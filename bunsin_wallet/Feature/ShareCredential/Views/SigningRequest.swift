//
//  SigningRequest.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/10/24.
//

import SwiftUI

struct SigningRequest: View {

    var args: SharingCredentialArgs

    @Environment(\.dismiss) private var dismiss
    @Binding var showSigingRequest: String?
    @State private var path: [ScreensOnFullScreen] = []
    @State private var viewModel = SigningRequestViewModel()

    init(
        args: SharingCredentialArgs,
        showSigingRequest: Binding<String?>
    ) {
        self.args = args
        self._showSigingRequest = showSigingRequest
    }

    fileprivate init(
        previewModel: SigningRequestViewModel,
        args: SharingCredentialArgs,
        showSigingRequest: Binding<String?>
    ) {
        self.args = args
        self._viewModel = State(initialValue: previewModel)
        self._showSigingRequest = showSigingRequest
    }

    private var cancelButton: some View {
        VStack(alignment: .leading) {
            HStack {
                Button("cancel") {
                    self.dismiss()
                }
                Spacer()
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading) {
            Text("sign_and_submit_to_boolcheck")
                .font(.title2)
                .bold()
                .modifier(Title2Black())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var walletToBoolcheckLogo: some View {
        HStack {
            Group {
                Image("logo_ownd").resizable().scaledToFit()
            }
            .frame(width: 88, height: 88)
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray, lineWidth: 1)
            )

            Image(systemName: "arrow.forward")
                .modifier(TitleGray())
                .fontWeight(.black)
                .padding(.horizontal, 8)

            Group {
                Image("logo_boolcheck")  // todo: use clientInfo.logoImage
                /*
                if let clientInfo = self.viewModel.model.clientInfo {
                    clientInfo.logoImage.scaledToFit()
                }
                else {
                    ImageLoader.questionMark
                }
                 */
            }
            .frame(width: 88, height: 88)
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray, lineWidth: 1)
            )
        }
    }

    private var signingContentDescription: some View {
        VStack {
            Text("signing_content")
                .font(.title3)
                .bold()
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modifier(BodyBlack())
            if let url = self.viewModel.model.signingUrl,
                let comment = self.viewModel.model.signingComment
            {
                Text(
                    String(
                        format: NSLocalizedString("signing_content_url", comment: ""),
                        url)
                )
                .padding(.vertical, 1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modifier(BodyGray())
                Text(
                    String(
                        format: NSLocalizedString("signing_content_bool_value", comment: ""),
                        self.viewModel.model.boolValueAsString())
                )
                .padding(.vertical, 1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modifier(BodyGray())
                Text(
                    String(
                        format: NSLocalizedString("signing_content_comment", comment: ""), comment)
                )
                .padding(.vertical, 1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modifier(BodyGray())
            }
        }
    }

    private func organizationInfo() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            Text("recipient _organization_information")
                .font(.title3)
                .fontWeight(.light)
                .modifier(BodyGray())
                .padding(.bottom, 12)
            if let clientInfo = self.viewModel.model.clientInfo {
                RecipientOrgInfo(
                    clientInfo: clientInfo
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
    }

    private var nextButton: some View {
        VStack {
            ActionButtonBlack(
                title: "Proceed to next",
                action: {
                    path.append(ScreensOnFullScreen.credentialList)
                }
            )
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { _ in
                Group {
                    ScrollView {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        else {
                            VStack {
                                cancelButton
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                                Divider()
                                    .padding(.bottom, 8)
                                VStack {
                                    headerView
                                    walletToBoolcheckLogo
                                        .padding(.vertical, 16)
                                    if (viewModel.isCommentVcRequired()) {
                                        signingContentDescription
                                    }
                                    organizationInfo()
                                        .padding(.top, 14)
                                    nextButton
                                        .padding(.top, 8)
                                }.padding(.horizontal, 16)

                            }
                        }
                    }
                }
            }
            .navigationDestination(for: ScreensOnFullScreen.self) { screen in
                switch screen {
                    case .credentialList:
                        SelectCredential(
                            presentationDefinition: viewModel.presentationDefinition,
                            path: $path
                        )
                    case .submitCredential(let selectedCredential):
                        let isAnonymous = selectedCredential == nil
                        let credentials =
                            viewModel.isCommentVcRequired()
                            ? [
                                selectedCredential,
                                viewModel.issueCommentCredential(isAnonymous: isAnonymous),
                            ] : [selectedCredential]
                        SubmitCredentials(
                            credentials: credentials,
                            path: $path,
                            showSigningRequest: $showSigingRequest
                        ).environment(viewModel)
                    default:
                        EmptyView()
                }
            }
            .onAppear {
                Task {
                    do {
                        try await self.viewModel.loadData(vpUrl: args.url)
                    }
                    catch {
                        print("error occurred while loading data : \(error)")
                    }
                }
            }
            .alert(isPresented: $viewModel.model.showAlert) {
                Alert(
                    title: Text(viewModel.model.alertTitle),
                    message: Text(viewModel.model.alertMessage),
                    dismissButton: .default(Text("OK")) {
                        self.dismiss()
                    }
                )
            }
        }
    }
}

#Preview("Default") {
    let url = "openid4vp://xxx"
    let args = SharingCredentialArgs()
    args.url = url
    return SigningRequest(
        previewModel: SigningRequestPreviewModel(),
        args: args,
        showSigingRequest: .constant(url)
    )
}

#Preview("Broken Url") {
    let args = SharingCredentialArgs()
    return SigningRequest(
        previewModel: SigningRequestPreviewModel(),
        args: args,
        showSigingRequest: .constant("")
    )
}
