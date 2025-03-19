//
//  SelectCredentialModel.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/10/28.
//

struct SelectCredentialModel {
    var selectedCredential: Credential? = nil
    var credentialChoices: [(String, Credential?)] = []
    var showAlert = false
    var alertTitle = ""
    var alertMessage = ""
}
