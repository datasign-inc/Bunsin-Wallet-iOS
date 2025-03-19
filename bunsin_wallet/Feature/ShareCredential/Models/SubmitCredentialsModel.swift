//
//  SubmitCredentialsModel.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/10/30.
//

struct SubmitCredentialsModel {
    // 将来的に複数の所属VCを提示する可能性があるため、配列で保持する。
    var affiliationCredentials: [Credential] = []
    var affiliationCredRequiredClaims: [DisclosureWithOptionality] = []
    var affiliationCredUserSelectableClaims: [DisclosureWithOptionality] = []
    var affiliationCredUndisclosedClaims: [DisclosureWithOptionality] = []
    var affiliationCredInputDescriptor: InputDescriptor? = nil

    // コメントクレデンシャルは常に1つの前提
    var commentCredential: Credential? = nil
    var commentCredentialInputDescriptor: InputDescriptor? = nil

    var locationAfterVp: String? = nil

    var showAlert = false
    var alertTitle = ""
    var alertMessage = ""
}
