//
//  SigningRequestPreviewModel.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/10/25.
//

class SigningRequestPreviewModel: SigningRequestViewModel {

    override func setSigningContent() {

    }

    override func loadData(vpUrl: String?) async {
        isLoading = true
        print("load dummy data..")

        guard let _ = vpUrl else {
            model.showAlert = true
            model.alertTitle = "invalid url"
            model.alertMessage = "invalid vp url"
            return
        }

        model = SigningRequestModel(
            signingUrl: "https://example.com/",
            signingBoolValue: 0,
            signingComment:
                "このXアカウントは前澤友作のアカウントではありません。本物の前澤友作のアカウントはこちらです。https://x.com/yousuck2020",

            clientInfo: ClientInfo(
                clientId: "https://www.ownd-project.com/",
                name: "Boolcheck",
                logoUrl: "https://www.ownd-project.com/img/logo_only.png",
                policyUrl: "https://boolcheck.example.com/policy",
                tosUrl: "https://boolcheck.example.com/tos",
                certificateInfo:
                    CertificateInfo(
                        domain: "ownd-project.com",
                        organization: "DataSign Inc.",
                        locality: "",
                        state: "Tokyo",
                        country: "JP",
                        street: "",
                        email: "support@ownd-project.com",
                        issuer:
                            CertificateInfo(
                                domain: "Sectigo ECC Organization Validation Secure Server CA",
                                organization: "Sectigo Limited",
                                locality: "Salford",
                                state: "Greater Manchester",
                                country: "GB",
                                street: "",
                                email: "support@ownd-project.com",
                                issuer: nil
                            )
                    )
            )
        )

        isLoading = false
    }
}
