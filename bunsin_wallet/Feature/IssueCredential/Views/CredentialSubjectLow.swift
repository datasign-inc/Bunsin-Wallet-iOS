//
//  CredentialSubjectLow.swift
//  bunsin_wallet
//
//  Created by SadamuMatsuoka on 2023/12/30.
//

import SwiftUI

struct CredentialSubjectLow: View {
    var item: String
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey(item))
                .modifier(BodyBlack())
        }
        .padding(.vertical, 3)  // 上下のpaddingに対応
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let modelData = ModelData()
    modelData.loadIssuerMetaDataList()
    let credSupported =
        modelData.issuerMetaDataList[2].credentialConfigurationsSupported[
            "ParticipationCertificate"]
        as! CredentialSupportedJwtVcJson
    let displayNames = Array(credSupported.credentialDefinition.credentialSubject!.keys)
    return CredentialSubjectLow(item: displayNames.first!)
}
