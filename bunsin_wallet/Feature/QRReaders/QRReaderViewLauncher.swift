//
//  QRReaderViewLauncher.swift
//  bunsin_wallet
//
//  Created by 若葉良介 on 2024/02/13.
//

import SwiftUI

struct QRReaderViewLauncher: View {
    @Environment(SharingRequestModel.self) var sharingRequestModel
    @Binding var selectedTab: String

    @State private var dataReadByQRReader = DataReadByQRReader()

    @State private var navigateToQRReaderView = false
    @State private var navigateToCredentialOffer = false
    @State private var navigateToVerificationView = false
    @State private var navigateToSigningRequest: String? = nil
    @State private var nextScreen: ScreensOnFullScreen = .root

    var body: some View {
        VStack {
            Text("")
                .fullScreenCover(
                    isPresented: $navigateToQRReaderView,
                    onDismiss: didDismissQRReader
                ) {
                    QRReaderView(nextScreen: $nextScreen)
                        .environment(dataReadByQRReader)
                }
                .fullScreenCover(
                    isPresented: $navigateToCredentialOffer,
                    onDismiss: didDismiss
                ) {
                    if let args = dataReadByQRReader.credentialOfferArgs {
                        CredentialOfferView().environment(args)
                    }
                    else {
                        EmptyView()
                    }
                }
                .fullScreenCover(
                    item: $navigateToSigningRequest,
                    onDismiss: didDismissSigningRequest
                ) { dummyValue in
                    if let args = dataReadByQRReader.sharingCredentialArgs {
                        SigningRequest(args: args, showSigingRequest: $navigateToSigningRequest)
                    }
                    else {
                        EmptyView()
                    }
                }
                .fullScreenCover(
                    isPresented: $navigateToVerificationView,
                    onDismiss: didDismiss
                ) {
                    if let args = dataReadByQRReader.verificationArgs {
                        Verification().environment(args)
                    }
                    else {
                        EmptyView()
                    }
                }
        }
        .onAppear {
            navigateToQRReaderView = true
        }
    }

    func didDismiss() {
        selectedTab = "Credential"
    }

    func didDismissQRReader() {
        // 次の遷移先を開く
        switch nextScreen {
            case .credentialOffer:
                print("credentialOffer")
                navigateToCredentialOffer.toggle()
            case .sharingRequest:
                print("sharingRequest")

                //todo: improve screen transition control
                navigateToSigningRequest = "dummyValue"
            case .verification:
                print("verification")
                navigateToVerificationView.toggle()
            default:
                selectedTab = "Credential"
        }
    }

    func didDismissSigningRequest() {
        selectedTab = "Credential"
    }
}

#Preview {
    QRReaderViewLauncher(selectedTab: .constant("Reader"))
}
