//
//  CredentialDetail.swift
//  bunsin_wallet
//
//  Created by 若葉良介 on 2023/12/21.
//

import SwiftUI

struct CredentialDetail: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(SharingRequestModel.self) var sharingRequestModel: SharingRequestModel?
    var credential: Credential
    var viewModel: CredentialDetailViewModel
    var deleteAction: (() -> Void)?

    @State private var showingQRCodeModal: Bool = false
    @State private var navigateToIssuerDetail: Bool = false
    @State private var showAlert = false
    @State private var userSelectableClaims: [DisclosureWithOptionality] = []
    @Binding var path: [ScreensOnFullScreen]

    init(
        viewModel: CredentialDetailViewModel = CredentialDetailViewModel(),
        credential: Credential,
        path: Binding<[ScreensOnFullScreen]>,
        deleteAction: (() -> Void)? = nil
    ) {
        print("init")
        self.viewModel = viewModel
        self.credential = credential
        self._path = path
        self.deleteAction = deleteAction
    }

    private var headerView: some View {
        VStack(alignment: .leading) {
            HStack {
                Button("back") {
                    // self.presentationMode.wrappedValue.dismiss()
                }
                .padding(.vertical, 16)
                Spacer()
            }
            Text("sending_information")
                .font(.title)
                .modifier(Title3Black())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var qrCodeSection: some View {
        Group {
            VStack {
                CredentialRow(credential: self.credential)
                    .aspectRatio(1.6, contentMode: .fit)
                    .frame(maxWidth: .infinity)

                let issuedByText = String(
                    format: NSLocalizedString("IssuedBy", comment: ""),
                    credential.issuerDisplayName)
                Text(issuedByText)
                    .underline()
                    .modifier(BodyGray())
                    .onTapGesture {
                        self.navigateToIssuerDetail = true
                    }
                    .padding(.vertical, 8)

                if self.credential.format == "jwt_vc_json" {
                    Text("display_qr_code")
                        .underline()
                        .modifier(BodyGray())
                        .padding(.vertical, 8)
                        .onTapGesture {
                            self.showingQRCodeModal = true
                        }
                        .padding(.vertical, 8)
                }
            }
        }
    }

    private var claimsToBeDisclosed: some View {
        return Group {
            ForEach(viewModel.requiredClaims, id: \.self.disclosure.id) { it in
                DisclosureRow(
                    vpMode: true,
                    submitDisclosure: .constant(it)
                )
            }

            Text("select_sharing_information")
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modifier(BodyBlack())
            ForEach($userSelectableClaims, id: \.self.disclosure.id) { $claim in
                DisclosureRow(
                    vpMode: true,
                    submitDisclosure: $claim
                )
            }

        }

    }

    private var claimsSection: some View {
        VStack {
            Text("Contents of this certificate")
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modifier(BodyGray())

            if let disclosureDict = credential.disclosure {
                ForEach(
                    sortedClaims(disclosureDict, credential: credential), id: \.key
                ) {
                    key, value in
                    let localizedKey = credential.getLocalizedKeyName(key: key)
                    let submitDisclosure = DisclosureWithOptionality(
                        disclosure: Disclosure(
                            disclosure: nil, key: key, value: value, localizedKey: localizedKey),
                        isSubmit: false,
                        isUserSelectable: false
                    )
                    DisclosureRow(
                        vpMode: false,
                        submitDisclosure: .constant(submitDisclosure)
                    )
                }
            }
        }
    }

    private var historySection: some View {
        VStack {
            Text("History of information provided")
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modifier(BodyGray())
            LazyVStack(spacing: 16) {
                ForEach(self.viewModel.dataModel.sharingHistories, id: \.createdAt) { history in
                    HistoryRow(history: history)
                        .padding(.vertical, 6)
                }
            }
        }
    }

    var body: some View {
        Group {
            if viewModel.dataModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
            else {
                ScrollView {
                    VStack {
                        qrCodeSection
                        claimsSection
                        historySection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .navigationTitle(self.credential.getLocalizedCredentialName())
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $navigateToIssuerDetail) {
                    IssuerDetail(credential: credential)
                }
                .sheet(isPresented: $showingQRCodeModal) {
                    DisplayQRCode(credential: credential)
                }
                .toolbar {
                    if deleteAction != nil {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Button(action: { showAlert = true }) {
                                    Text("Delete")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                            }
                        }
                    }
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Confirm To Delete"),
                        message: Text("Are you sure to delete this credential?"),
                        primaryButton: .destructive(Text("Delete")) {
                            deleteAction?()
                            presentationMode.wrappedValue.dismiss()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
        .onAppear {
            print("onAppear")
            Task {
                await viewModel.loadData(credential: credential)
            }
        }
    }

}

#Preview("1. format: sd-jwt, card: image") {
    let modelData = ModelData()
    modelData.loadCredentials()
    return CredentialDetail(
        viewModel: DetailPreviewModel(),
        credential: modelData.credentials[0],
        path: .constant([])
    )
}

#Preview("2. format: sd-jwt, card: bg-color") {
    let modelData = ModelData()
    modelData.loadCredentials()
    return CredentialDetail(
        viewModel: DetailPreviewModel(),
        credential: modelData.credentials[1],
        path: .constant([])
    )
}

#Preview("3. format: jwt-vc-json") {
    let modelData = ModelData()
    modelData.loadCredentials()
    return CredentialDetail(
        viewModel: DetailPreviewModel(),
        credential: modelData.credentials[2],
        path: .constant([])
    )
}

#Preview("4. mode: vp-sharing") {
    let modelData = ModelData()
    modelData.loadCredentials()
    let viewModel = DetailVPModePreviewModel()
    let pd = viewModel.dummyPresentationDefinition1()
    return CredentialDetail(
        viewModel: viewModel,
        credential: modelData.credentials[2],
        path: .constant([])
    ).environment(SharingRequestModel(presentationDefinition: pd))
}

#Preview("5. mode: vp-sharing with optional field") {
    let modelData = ModelData()
    modelData.loadCredentials()
    let viewModel = DetailVPModePreviewModel()
    let pd = viewModel.dummyPresentationDefinition2()
    return CredentialDetail(
        viewModel: viewModel,
        credential: modelData.credentials[2],
        path: .constant([])
    ).environment(SharingRequestModel(presentationDefinition: pd))
}
