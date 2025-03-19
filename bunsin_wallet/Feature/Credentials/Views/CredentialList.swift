//
//  CredentialList.swift
//  bunsin_wallet
//
//  Created by 若葉良介 on 2023/12/21.
//

import SwiftUI

// 一時的に AddCertificates.swift から退避。(AddCertificates.swiftを削除したため)
// todo: 適切な場所に移動すべき
@Observable
class DataReadByQRReader {
    var credentialOfferArgs: CredentialOfferArgs?
    var sharingCredentialArgs: SharingCredentialArgs?
    var verificationArgs: VerificationArgs?
}

struct RefreshableScrollView<Content: View>: View {
    let onRefresh: () async -> Void
    @ViewBuilder var content: () -> Content

    @State private var isRefreshing = false

    var body: some View {
        ScrollView {
            VStack {
                if isRefreshing {
                    ProgressView()
                        .padding()
                }
                content()
            }
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: ScrollOffsetKey.self, value: proxy.frame(in: .global).minY)
                }
            )
        }
        .onPreferenceChange(ScrollOffsetKey.self) { minY in
            if minY > 25, !isRefreshing {
                Task {
                    await refresh()
                }
            }
        }
    }

    @MainActor
    private func refresh() async {
        isRefreshing = true
        await onRefresh()
        isRefreshing = false
    }
}

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct CredentialList: View {
    @Environment(SharingRequestModel.self) var sharingRequestModel

    @State private var dataReadByQRReader = DataReadByQRReader()
    @State private var viewModel: CredentialListViewModel

    @State private var nextScreen: ScreensOnFullScreen = .root
    @State private var showQRCodeReader = false
    @State private var showAlert = false
    @State private var showCredentialOfferView = false

    // full screenから開かれたDetailで必要なのでここでは空の配列を固定で持つ
    @State private var dummyPath: [ScreensOnFullScreen] = []

    init(viewModel: CredentialListViewModel = CredentialListViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.dataModel.isLoading {
                    loadingView
                }
                else if viewModel.dataModel.credentials.isEmpty {
                    emptyStateView
                }
                else {
                    credentialListView
                }
            }
            .navigationBarTitle("Credential List", displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .fullScreenCover(isPresented: $showQRCodeReader, onDismiss: afterQRCodeRead) {
                QRReaderView(nextScreen: $nextScreen)
                    .environment(dataReadByQRReader)
                    .environment(sharingRequestModel)
            }
            .fullScreenCover(
                isPresented: $showCredentialOfferView, onDismiss: didDismissCredentialOffer
            ) {
                if let args = dataReadByQRReader.credentialOfferArgs {
                    CredentialOfferView().environment(args)
                }
                else {
                    EmptyView()
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("invalid_qr_code"),
                    message: Text("scan_credential_offer_qr"),
                    dismissButton: .default(Text("OK")) {
                        showAlert = false
                    }
                )
            }
        }
        .onAppear {
            print("onAppear@CredentialList")
            Task {
                viewModel.loadData()
            }
        }
    }

    private var loadingView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
    }

    private var emptyStateView: some View {
        GeometryReader { geometry in
            HStack {
                Spacer()
                VStack {
                    Text("no_certificate")
                        .modifier(LargeTitleBlack())
                        .padding(.vertical, 64)
                    Image("tap_to_add")
                        .resizable()
                        .aspectRatio(1.6, contentMode: .fit)
                        .frame(
                            width: geometry.size.width * 0.85,
                            height: geometry.size.width * 0.53125
                        )
                        .onTapGesture {
                            showQRCodeReader = true
                        }
                }
                Spacer()
            }
        }
    }

    private var credentialListView: some View {
        RefreshableScrollView(onRefresh: { viewModel.reload() }) {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.dataModel.credentials) { credential in
                    VStack(alignment: .leading) {
                        Text(credential.getLocalizedCredentialName())
                            .font(.headline)
                            .padding(.leading, 16)
                        NavigationLink(
                            destination: CredentialDetail(
                                credential: credential,
                                path: $dummyPath,
                                deleteAction: {
                                    Task {
                                        viewModel.deleteCredential(credential: credential)
                                    }
                                }
                            )
                        ) {
                            CredentialRow(credential: credential)
                                .aspectRatio(1.6, contentMode: .fit)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }.refreshable {
            viewModel.reload()
        }
        .overlay(
            FloatingActionButton(
                onButtonTap: {
                    showQRCodeReader = true
                }
            ),
            alignment: .bottomTrailing
        )
    }

    private func didDismissCredentialOffer() {
        showCredentialOfferView = false
        viewModel.reload()
    }

    private func afterQRCodeRead() {
        if nextScreen == .credentialOffer {
            showCredentialOfferView.toggle()
        }
        else {
            if nextScreen != .root {
                showAlert = true
            }
        }
    }
}

#Preview("Empty") {
    CredentialList()
}

#Preview("Not Empty") {
    CredentialList(viewModel: PreviewModel())
}
