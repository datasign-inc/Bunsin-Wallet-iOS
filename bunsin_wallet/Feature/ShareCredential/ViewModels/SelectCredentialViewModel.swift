//
//  SelectCredentialViewModel.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/10/28.
//

import Foundation
import SwiftUI

@Observable
class SelectCredentialViewModel {

    var model: SelectCredentialModel = SelectCredentialModel()
    var isLoading = false
    var hasLoadedData = false

    @ObservationIgnored
    private let credentialDataManager = CredentialDataManager(container: nil)

    func updateSelectedCredential(selectedCredential: Credential?) {
        self.model.selectedCredential = selectedCredential
    }

    func getRadioButtonImage(credential: Credential?) -> String {
        return self.model.selectedCredential == credential ? "button.programmable" : "circle"
    }

    func getRadioButtonColor(credential: Credential?) -> Color {
        return self.model.selectedCredential == credential ? Color.blue : Color.gray
    }

    func loadData(presentationDefinition: PresentationDefinition?) async {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            print("now previewing")
            return
        }
        guard !hasLoadedData else { return }
        isLoading = true

        model.credentialChoices = []
        
        // SIOPv2の場合は、presentationDefinitionがnilであるため
        if let pred = presentationDefinition {
         for cred in credentialDataManager.getAllCredentials() {
            if let credential = cred.toCredential() {
                if pred.isSatisfy(credential: credential) {
                    if self.model.selectedCredential == nil {
                        self.model.selectedCredential = credential
                    }
                    model.credentialChoices.append(
                        (
                            cred.getCredentialName() ?? "Unknown",
                            credential
                        ))
                }
            }
        }
        }

        model.credentialChoices.append(
            (String(localized: "post_without_affiliation_certificate"), nil)
        )

        isLoading = false
        hasLoadedData = true
    }
}
