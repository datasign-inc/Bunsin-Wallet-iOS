//
//  RecipientOrgInfo.swift
//  bunsin_wallet
//
//  Created by SadamuMatsuoka on 2024/01/11.
//

import SwiftUI

struct RecipientOrgInfo: View {
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfUse = false
    @State private var hideOrgDetail = true

    var clientInfo: ClientInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            if !hideOrgDetail {
                detailSection
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                logoView
                    .frame(width: 36, height: 36)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                VStack(alignment: .leading) {
                    Text(clientInfo.certificateInfo?.organization ?? clientInfo.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .modifier(BodyBlack())
                        .padding(.bottom, 1)
                    if let issuer = clientInfo.certificateInfo?.issuer, clientInfo.verified {
                        HStack {
                            Image("verifier_mark")
                            Text("verified by").modifier(SubHeadLineGray())
                            Text(issuer.organization!).modifier(SubHeadLineGray())
                        }
                    }
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text(hideOrgDetail ? "▼" : "▲")
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .applyRoundForHeader(flag: hideOrgDetail)
        .onTapGesture {
            hideOrgDetail.toggle()
        }
    }

    private var logoView: some View {
        Group {
            if let logo = clientInfo.logoImage {
                logo
            }
            else {
                Color.clear
            }
        }
    }

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let certificateInfo = clientInfo.certificateInfo {
                certificateDetailSection(certificateInfo: certificateInfo)
            }
            else {
                fallbackDetailSection
            }
        }
    }

    private func certificateDetailSection(certificateInfo: CertificateInfo) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            detailItem(title: "domain", value: certificateInfo.domain)
            detailItem(title: "cert_location") {
                HStack {
                    Text(certificateInfo.state ?? "")
                    Text(certificateInfo.locality ?? "")
                }
            }
            detailItem(title: "cert_country", value: certificateInfo.country)
            detailItem(title: "contact", value: certificateInfo.domain ?? "Unknown")
            detailLink(title: "terms_of_use", url: clientInfo.tosUrl, isPresented: $showTermsOfUse)
            detailLink(
                title: "privacy_policy", url: clientInfo.policyUrl, isPresented: $showPrivacyPolicy)
        }
    }

    private var fallbackDetailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            detailLink(title: "terms_of_use", url: clientInfo.tosUrl, isPresented: $showTermsOfUse)
            detailLink(
                title: "privacy_policy", url: clientInfo.policyUrl, isPresented: $showPrivacyPolicy)
        }
        .padding(.vertical, 16)
    }

    private func detailItem(title: String, value: String?) -> some View {
        detailItem(title: title) {
            if let value = value {
                Text(value).modifier(BodyBlack())
            }
        }
    }

    private func detailItem(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey(title))
                .font(.title3)
                .fontWeight(.light)
                .modifier(BodyGray())
                .padding(.horizontal, 8)
            content().padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 80)
        .roundedBorder()
    }

    private func detailLink(title: String, url: String, isPresented: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey(title))
                .font(.title3)
                .fontWeight(.light)
                .modifier(BodyGray())
                .padding(.horizontal, 8)
            Button(action: {
                isPresented.wrappedValue = true
            }) {
                Text(url)
                    .modifier(BodyBlack())
                    .underline()
                    .sheet(isPresented: isPresented) {
                        SafariView(url: URL(string: url)!)
                    }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 80)
        .roundedBorder()
    }
}

extension View {

    fileprivate func applyRoundForHeader(flag: Bool) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: flag ? 8 : 1)
                .stroke(Color.gray, lineWidth: 1)
        )
    }

    fileprivate func roundedBorder() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 1)
                .stroke(Color.gray, lineWidth: 1)
        )
    }
}

#Preview {
    let modelData = ModelData()
    modelData.loadClientInfoList()
    return RecipientOrgInfo(clientInfo: modelData.clientInfoList[0])
}
