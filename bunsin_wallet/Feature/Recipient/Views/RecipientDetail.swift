//
//  RecipientDetail.swift
//  bunsin_wallet
//
//  Created by SadamuMatsuoka on 2024/02/02.
//

import SwiftUI

struct RecipientDetail: View {
    var sharingHistories: [History]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if let firstHistory = sharingHistories.first {
                        Text("recipient_organization_information")
                            .bold()
                            .modifier(BodyGray())
                            .padding(.top, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
                        RecipientInfo(sharingHistory: firstHistory)
                    }
                    else {
                        Text("No history available")
                    }
                }
                VStack {
                    Text("information_provision_history")
                        .bold()
                        .modifier(BodyGray())
                        .padding(.top, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ

                    VStack {
                        let addedIndex = sharingHistories.enumerated().map {
                            ($0.offset, $0.element)
                        }
                        ForEach(addedIndex, id: \.0) { historyWithIndex in
                            let (_, history) = historyWithIndex
                            NavigationLink(destination: RecipientClaims(sharingHistory: history)) {
                                HistoryRow(history: history)
                                    .padding(.bottom, 48)
                            }
                        }
                    }.padding(.top, 24)
                }.padding(.top, 40)
            }
            .padding(.horizontal, 16)  // 左右に16dpのパディング
            .navigationBarTitle("SharingTo", displayMode: .inline)
        }
    }
}

#Preview("1") {
    let modelData = ModelData()
    modelData.loadCredentialSharingHistories()
    return RecipientDetail(
        sharingHistories: modelData.credentialSharingHistories
    )
}
