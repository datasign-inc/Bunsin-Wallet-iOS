//
//  RecipientClaims.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/02/18.
//

import SwiftUI

struct RecipientClaims: View {
    @State var viewModel = RecipientClaimsViewModel()  // should be private
    var sharingHistory: History

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                else {
                    ScrollView {
                        VStack(alignment: .leading) {
                            LazyVStack(spacing: 16) {
                                Text(viewModel.rpName)
                                    .padding(.top, 16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer()

                                ForEach(viewModel.claimsInfo, id: \.claimValue) { info in
                                    Text(info.claimKey)
                                    Text(info.claimValue)
                                    if let value = info.purpose {
                                        if value != "" {
                                            Text(value)
                                                .modifier(BodyGray())
                                        }
                                    }
                                    Spacer()
                                }.frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 16)
                        .navigationBarTitle(viewModel.title, displayMode: .inline)
                    }
                }
            }.onAppear {
                viewModel.loadClaimsInfo(sharingHistory: sharingHistory)
            }
        }
    }
}

#Preview {
    let modelData = ModelData()
    modelData.loadCredentialSharingHistories()
    return RecipientClaims(
        viewModel: RecipientClaimsPreviewModel(),
        sharingHistory: modelData.credentialSharingHistories[0])
}
