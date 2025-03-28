//
//  IssuerDetail.swift
//  bunsin_wallet
//
//  Created by SadamuMatsuoka on 2023/12/30.
//

import SwiftUI

struct IssuerDetail: View {
    @State private var viewModel: IssuerDetailViewModel
    var issuerMetadata: CredentialIssuerMetadata? = nil
    var credential: Credential?
    var showTitle: Bool = true

    init(
        viewModel: IssuerDetailViewModel = IssuerDetailViewModel(),
        issuerMetadata: CredentialIssuerMetadata? = nil,
        credential: Credential? = nil,
        showTitle: Bool = true
    ) {
        self.viewModel = viewModel
        self.issuerMetadata = issuerMetadata != nil ? issuerMetadata : credential?.metaData
        self.credential = credential
        self.showTitle = showTitle
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    let displayName =
                        issuerMetadata?.getCredentialIssuerDisplayName() ?? "Unknown Issuer Name"
                    Text(displayName).modifier(TitleBlack())
                        .frame(height: 60)
                }
                .padding(.top, 16)

                if let verifierCertificate = viewModel.certInfo {
                    if let issuerCertificate = verifierCertificate.issuer {
                        HStack {
                            Image("verifier_mark")
                            Text("verified by \(issuerCertificate.organization ?? "")").modifier(
                                SubHeadLineGray())
                        }
                        .padding(.bottom, 16)
                        .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text("cert_location").modifier(SubHeadLineGray())
                        HStack {
                            if let street = verifierCertificate.street {
                                Text(street)
                            }
                            if let locality = verifierCertificate.locality {
                                Text(locality)
                            }
                            if let state = verifierCertificate.state {
                                Text(state)
                            }
                        }.modifier(BodyBlack())
                    }
                    .padding(.vertical, 6)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("cert_country").modifier(SubHeadLineGray())
                        Text(verifierCertificate.country ?? "N/A").modifier(BodyBlack())
                    }
                    .padding(.vertical, 6)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("cert_domain").modifier(SubHeadLineGray())
                        Text(verifierCertificate.domain ?? "N/A").modifier(BodyBlack())
                    }
                    .padding(.vertical, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, showTitle ? 16 : 0)
            .navigationBarTitle(
                showTitle ? "issuing_authority_information" : "", displayMode: .inline)
        }
        .onAppear {
            Task {
                await viewModel.loadData(
                    credential: self.credential
                )
            }
        }
    }
}

#Preview("verified issuer") {
    let modelData = ModelData()
    modelData.loadIssuerMetaDataList()
    modelData.loadCredentials()
    return IssuerDetail(
        viewModel: IssuerDetailPreviewModel(),
        issuerMetadata: modelData.issuerMetaDataList[0]
    )
}

#Preview("unverified issuer") {
    let modelData = ModelData()
    modelData.loadIssuerMetaDataList()
    modelData.loadCredentials()

    return Group {
        IssuerDetail(
            viewModel: IssuerDetailPreviewModel2(),
            issuerMetadata: modelData.issuerMetaDataList[1]
        )
    }
}

/*
#Preview("From TLS Session") {
    let modelData = ModelData()
    modelData.loadIssuerMetaDataList()

    return Group {
        IssuerDetail(
            viewModel: IssuerDetailPreviewModel3(),
            issuerMetadata: modelData.issuerMetaDataList[1]
        )
        )
    }
}
*/
