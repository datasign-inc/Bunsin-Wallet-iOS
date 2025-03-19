//
//  Home.swift
//  bunsin_wallet
//
//  Created by 若葉良介 on 2023/12/21.
//

import SwiftUI

struct Home: View {
    @State private var selectedTab: String = "Credential"

    // todo: 大域的に定義する必要があるか、要見直
    @State private var sharingRequestModel = SharingRequestModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            CredentialList()
                .tabItem {
                    Label("Credential", systemImage: "person.text.rectangle")
                }
                .tag("Credential")
                .environment(sharingRequestModel)
            RecipientList()
                .tabItem {
                    Label("SharingTo", systemImage: "house.fill")
                }
                .tag("Recipient")
            QRReaderViewLauncher(selectedTab: $selectedTab)
                .tabItem {
                    Label("Reader", systemImage: "qrcode.viewfinder")
                }
                .tag("Reader")
                .environment(sharingRequestModel)
            Setting()
                .tabItem {
                    Label("Setting", systemImage: "line.3.horizontal")
                }
                .tag("Setting")
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    Home()
}
