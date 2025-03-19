//
//  Credential.swift
//  bunsin_wallet
//
//  Created by 若葉良介 on 2023/12/21.
//

import Foundation
import SwiftUI

struct Credential: Codable, Identifiable, Hashable {
    var id: String
    var format: String
    var payload: String
    var issuer: String
    let issuerDisplayName: String
    var issuedAt: String
    var logoUrl: String?
    var backgroundColor: String?
    var backgroundImageUrl: String?
    var textColor: String?
    var credentialType: String
    // var disclosure: Dictionary<String, String>?以下は同様の意味
    var disclosure: [String: String]?
    var certificates: [Certificate?]?
    var qrDisplay: String
    var metaData: CredentialIssuerMetadata

    var backgroundImage: AnyView? {
        if let url = backgroundImageUrl {
            return ImageLoader.loadImage(from: url, fallBack: ImageLoader.credentialCard)
        }
        return nil
    }

    var logoImage: AnyView? {
        if let url = logoUrl {
            return ImageLoader.loadImage(from: url)
        }
        return nil
    }

    struct Certificate: Codable {
        var CN: String
        var O: String
        var ST: String
        var L: String?
        var STREET: String?
        var C: String
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Credential, rhs: Credential) -> Bool {
        return lhs.id == rhs.id
    }

    func getLocalizedCredentialName(locale: String = "ja-JP") -> String {
        let supportedCredential = metaData.credentialConfigurationsSupported
        guard let thisCredentialMetadata = supportedCredential[credentialType] else {
            return credentialType
        }
        return thisCredentialMetadata.getLocalizedCredentialName(locale: locale)
    }

    func getLocalizedKeyName(key: String, locale: String = "ja-JP") -> String {
        let supportedCredential = metaData.credentialConfigurationsSupported
        guard let thisCredentialMetadata = supportedCredential[credentialType] else {
            return key
        }
        switch thisCredentialMetadata {
            case let vcSdJwt as CredentialSupportedVcSdJwt:
                guard let claims = vcSdJwt.claims,
                    let claim = claims[key],
                    let localized = claim.getLocalizedClaimName(locale: locale)
                else {
                    return key
                }
                return localized
            case let jwtVcJson as CredentialSupportedJwtVcJson:
                let credentialDefinition = jwtVcJson.credentialDefinition
                guard let credentialSubject = credentialDefinition.credentialSubject,
                    let claim = credentialSubject[key],
                    let localized = claim.getLocalizedClaimName(locale: locale)
                else {
                    return key
                }
                return localized
            default:
                return key
        }
    }

    func createSubmissionCredential(
        inputDescriptor: InputDescriptor,
        discloseClaims: [DisclosureWithOptionality]
    )
        -> SubmissionCredential
    {
        let types = try! VCIMetadataUtil.extractTypes(
            format: self.format,
            credential: self.payload)
        let submissionCredential = SubmissionCredential(
            id: self.id,
            format: self.format,
            types: types,
            credential: self.payload,
            inputDescriptor: inputDescriptor,
            discloseClaims: discloseClaims
        )
        return submissionCredential
    }

    private func convertDateToUnixTimestamp(dateString: String) -> Int64? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)  // 必要に応じてタイムゾーンを設定
        guard let date = dateFormatter.date(from: dateString) else {
            return nil  // 変換失敗時はnilを返す
        }
        return Int64(date.timeIntervalSince1970)
    }

    func toDatastoreFormat() -> Datastore_CredentialData {
        do {
            let jsonData = try JSONEncoder().encode(self.metaData)
            // JSONデータを文字列に変換（オプション）
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                var credential = Datastore_CredentialData()
                credential.id = self.id
                credential.format = self.format
                credential.credential = self.payload
                credential.iss = self.issuer
                credential.iat = self.convertDateToUnixTimestamp(dateString: issuedAt)!
                credential.type = self.credentialType
                credential.credentialIssuerMetadata = jsonString

                credential.cNonce = ""
                credential.cNonceExpiresIn = 3600
                credential.accessToken = ""
                return credential
            }
            else {
                fatalError("unable to convert metadata to string")
            }
        }
        catch {
            fatalError("unable to convert metadata to string")
        }
    }
}
