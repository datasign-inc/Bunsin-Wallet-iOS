//
//  RecipientLow.swift
//  bunsin_wallet
//
//  Created by SadamuMatsuoka on 2024/01/30.
//

import SwiftUI

struct RecipientRow: View {
    var sharingHistory: History

    var body: some View {
        HStack {
            Group {
                if isClientBoolcheck(clientId: sharingHistory.rp) {
                    Image("logo_boolcheck").resizable().scaledToFit()
                }
                else {
                    switch sharingHistory {
                        case let credential as CredentialSharingHistory:
                            if let logoView = credential.logoImage {
                                logoView
                            }
                            else {
                                Color.clear
                            }
                        case let idToken as IdTokenSharingHistory:
                            Color.clear  // todo: add `logoUri` to IdTokenSharingHistory
                        default:
                            Color.clear
                    }
                }
            }
            .frame(width: 35, height: 35)
            .padding(.vertical, 4)
            .padding(.horizontal, 4)

            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Group {
                        let defaultText = Text("Unknown").modifier(BodyBlack())
                        switch sharingHistory {
                            case let credential as CredentialSharingHistory:
                                if credential.rpName != "" {
                                    Text(credential.rpName)
                                        .modifier(BodyBlack())
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                else {
                                    defaultText
                                }
                            case let idToken as IdTokenSharingHistory:
                                Text(idToken.rp)  // todo: add `rpName` to IdTokenSharingHistory
                                    .modifier(BodyBlack())
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            default:
                                defaultText
                        }
                    }.padding(.bottom, 8)
                    HStack {
                        (Text(String(localized: "date_of_last_information") + " :"))
                            .modifier(BodyGray())
                        Spacer()
                        Text(DateFormatterUtil.formatDate(sharingHistory.createdAt, true))
                            .modifier(BodyGray())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
                Spacer()

                Image(systemName: "chevron.forward").modifier(Title3Gray())
            }

        }
    }
}

#Preview {
    let modelData = ModelData()
    modelData.loadCredentialSharingHistories()
    return RecipientRow(
        sharingHistory: modelData.credentialSharingHistories[0]
    )
}
