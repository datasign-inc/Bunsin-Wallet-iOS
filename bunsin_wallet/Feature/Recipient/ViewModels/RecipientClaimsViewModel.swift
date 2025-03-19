//
//  RecipientClaimsViewModel.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/02/19.
//

import Foundation

@Observable class RecipientClaimsViewModel {
    var title: String = "Unknown"
    var rpName: String = "Unknown"
    var claimsInfo: [ClaimInfo] = []
    var hasLoadedData = false
    var isLoading = false

    private var credentialManager: CredentialDataManager

    init(credentialManager: CredentialDataManager = CredentialDataManager(container: nil)) {
        self.credentialManager = credentialManager
    }

    func loadClaimsInfo(sharingHistory: History) {
        guard !self.hasLoadedData else { return }
        self.isLoading = true

        switch sharingHistory {
            case let credential as CredentialSharingHistory:
                let claims = credential.claims
                self.claimsInfo = claims
                self.title = String(
                    format: NSLocalizedString("credential_sharing_time", comment: ""),
                    credential.createdAt)
                self.rpName = String(
                    format: NSLocalizedString("credential_recipient", comment: ""),
                    credential.rpName)
            case let idToken as IdTokenSharingHistory:
                self.claimsInfo = [
                    ClaimInfo(
                        claimKey: String(format: NSLocalizedString("user_id", comment: "")),
                        claimValue: idToken.thumbprint,
                        purpose:
                            String.localizedStringWithFormat(
                                NSLocalizedString("for_identifying_user", comment: ""))
                    )
                ]
                self.title = String(
                    format: NSLocalizedString("credential_sharing_time", comment: ""),
                    idToken.createdAt)
                self.rpName = String(
                    format: NSLocalizedString("credential_recipient", comment: ""),
                    idToken.rp)
            default:
                print("Unexpected history type")
        }

        self.isLoading = false
        self.hasLoadedData = true
    }
}
