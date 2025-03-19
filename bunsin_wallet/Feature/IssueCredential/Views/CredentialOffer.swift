//
//  CredentialOffer.swift
//  bunsin_wallet
//
//  Created by 若葉良介 on 2023/12/22.
//

import SwiftUI

enum AlertType: Identifiable {
    case issuanceSuccess
    case credentialOfferError
    case issuanceError
    var id: String {
        switch self {
            case .issuanceError: return "issuanceError"
            case .credentialOfferError: return "credentialOfferError"
            case .issuanceSuccess: return "issuanceSuccess"
        }
    }
}

struct CredentialOfferView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CredentialOfferArgs.self) var args
    @State var viewModel: CredentialOfferViewModel = .init()  //should be private
    @State private var navigateToPinInput = false

    @State private var alertType: AlertType?

    private func issueCredential(txCode: String?) async {
        do {
            try await viewModel.sendRequest(txCode: txCode)
            alertType = .issuanceSuccess
        }
        catch {
            alertType = .issuanceError
        }
    }

    private func handleCredentialIssue() async {
        if let offer = viewModel.dataModel.credentialOffer {
            if offer.isTxCodeRequired() {
                self.navigateToPinInput = true
            }
            else {
                await issueCredential(txCode: nil)
            }
        }
        else {
            alertType = .credentialOfferError
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.dataModel.isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                }
                else {
                    content
                }
            }
            .navigationBarTitle("", displayMode: .inline)
        }
        .onAppear {
            Task {
                if let credentialOfferString = args.credentialOffer,
                    let credentialOffer = CredentialOffer.fromString(credentialOfferString)
                {
                    do {
                        try await viewModel.loadData(credentialOffer)
                        try viewModel.validateRequiredData()
                    }
                    catch {
                        print("Failed to prepare data for issuing credential: \(error)")
                        alertType = .credentialOfferError
                    }
                }
                else {
                    print("Invalid credential offer format")
                    alertType = .credentialOfferError
                }
            }
        }
        .alert(item: $alertType) { type in
            switch type {
                case .credentialOfferError:
                    return Alert(
                        title: Text("error"),
                        message: Text("failed_to_load_info_for_issuance"),
                        dismissButton: .default(Text("OK")) {
                            self.dismiss()
                        }
                    )
                case .issuanceError:
                    return Alert(
                        title: Text("error"),
                        message: Text("error_occurred_while_issuing_certificate"),
                        dismissButton: .default(Text("OK")) {
                            self.dismiss()
                        }
                    )
                case .issuanceSuccess:
                    return Alert(
                        title: Text("complete"),
                        message: Text("added_new_certificate"),
                        dismissButton: .default(Text("OK")) {
                            self.dismiss()
                        }
                    )
            }

        }

    }

    @ViewBuilder
    private var content: some View {
        if let issuerMetaData = viewModel.dataModel.metaData?.credentialIssuerMetadata,
            let targetCredentialId = viewModel.dataModel.targetCredentialId,
            let targetCredential = issuerMetaData.credentialConfigurationsSupported[
                targetCredentialId]
        {
            contentWithMetaData(issuerMetaData, targetCredential)
        }
        else {
            // As long as validateRequiredData is executed, this code is unreachable.
            EmptyView()
        }
    }

    private func contentWithMetaData(
        _ issuerMetaData: CredentialIssuerMetadata, _ targetCredential: CredentialConfiguration
    ) -> some View {
        let locale = "ja-JP"  // This value should be obtained dynamically.
        let issuerDisplayName = issuerMetaData.getCredentialIssuerDisplayName(locale: locale)
        let credentialDisplayName = targetCredential.getLocalizedCredentialName(locale: locale)
        let displayNames = targetCredential.getLocalizedClaimNames(locale: locale)

        return VStack {
            HStack {
                Button("cancel") {
                    self.dismiss()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                Spacer()
            }

            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        Text(
                            String(
                                format: NSLocalizedString(
                                    "credentialOfferText", comment: ""),
                                issuerDisplayName,
                                credentialDisplayName)
                        )
                        .modifier(Title3Black())
                        Image("issue_confirmation")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width * 0.65)  // 横幅の65%に設定
                    }

                    Text("issuance_purpose")
                        .padding(.vertical, 8)
                        .padding(.top, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
                        .modifier(BodyGray())
                    Text("to_store_bunsin_wallet")
                        .modifier(BodyBlack())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Items to be issued")
                        .padding(.top, 8)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
                        .modifier(BodyGray())
                    if displayNames.count == 0 {
                        Text("no_information_available_to_display").frame(
                            maxWidth: .infinity, alignment: .leading)
                    }
                    else {
                        ForEach(displayNames, id: \.self) { displayName in
                            CredentialSubjectLow(item: displayName)
                        }

                    }
                    Text("issuing_authority_information")
                        .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
                        .modifier(BodyGray())
                        .padding(.top, 32)

                    IssuerDetail(
                        issuerMetadata: issuerMetaData, showTitle: false)
                    ActionButtonBlack(
                        title: "issue_credential",
                        action: {
                            Task {
                                await handleCredentialIssue()
                            }
                        }
                    )
                    .padding(.vertical, 16)
                    .navigationDestination(
                        isPresented: $navigateToPinInput,
                        destination: {
                            PinCodeInput { pinCode in
                                await issueCredential(txCode: pinCode)
                            }
                        }
                    )
                }
                .padding(.horizontal, 16)  // 左右に16dpのパディング
                .padding(.vertical, 16)
            }

        }
    }
}

#Preview("2. invalid credential offer") {
    let args = CredentialOfferArgs()
    args.credentialOffer =
        "openid-credential-offer://?credential_offer=broken"
    return CredentialOfferView(
        viewModel: CredentialOfferPreviewModel()
    ).environment(args)
}
