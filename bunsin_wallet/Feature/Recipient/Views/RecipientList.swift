//
//  RecipientList.swift
//  bunsin_wallet
//
//  Created by SadamuMatsuoka on 2024/02/01.
//

import SwiftUI

struct RecipientList: View {
    @State var viewModel: RecipientListViewModel = .init()  // shoule be private

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                else if viewModel.sharingHistories.isEmpty {
                    // 提供履歴が0件の場合の処理
                    Text("There is no provision history.")
                        .padding()
                        .modifier(TitleBlack())
                }
                else {
                    ScrollView {
                        VStack {
                            ForEach(viewModel.sharingHistories, id: \.rp) { sharingHistory in
                                if let data = viewModel.groupedSharingHistories[sharingHistory.rp] {
                                    NavigationLink(
                                        destination: RecipientDetail(sharingHistories: data)
                                    ) {
                                        RecipientRow(sharingHistory: sharingHistory)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationBarTitle("SharingTo", displayMode: .inline)
        }
        .onAppear {
            viewModel.loadSharingHistories()
        }
    }
}

#Preview("1") {
    RecipientList()
}

#Preview("2") {
    RecipientList(
        viewModel: RecipientListPreviewModel()
    )
}
