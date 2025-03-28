//
//  Metadata.swift
//  bunsin_wallet
//
//  Created by 若葉良介 on 2023/12/25.
//

import Foundation
import SwiftyJSON

struct Logo: Codable {
    let uri: String
    let altText: String?
}

struct BackgroundImage: Codable {
    let uri: String?
}

protocol Displayable: Codable {
    var name: String? { get }
    var locale: String? { get }
}

struct IssuerDisplay: Displayable {
    let name: String?
    let locale: String?
    let logo: Logo?
}

struct ClaimDisplay: Displayable {
    let name: String?
    let locale: String?
}

struct CredentialDisplay: Codable {
    let name: String
    let locale: String?
    let logo: Logo?
    let description: String?
    let backgroundColor: String?
    let backgroundImage: BackgroundImage?
    let textColor: String?
}

struct Claim: Codable {
    let mandatory: Bool?
    let valueType: String?
    let display: [ClaimDisplay]?

    func getLocalizedClaimName(locale: String) -> String? {
        guard let disp = display else {
            return nil
        }
        for elm in disp {
            if elm.locale == locale {
                return elm.name
            }
        }
        return nil
    }
}

struct ClaimOnlyMandatory: Codable {
    var mandatory: Bool?
}

struct ProofSigningAlgValuesSupported: Codable {
    let proofSigningAlgValuesSupported: [String]
}

struct CredentialResponseEncryption: Codable {
    let algValuesSupported: [String]
    let encValuesSupported: [String]
    let encryptionRequired: Bool
}

protocol CredentialConfiguration: Codable {
    var format: String { get }
    var scope: String? { get }
    var cryptographicBindingMethodsSupported: [String]? { get }
    var credentialSigningAlgValuesSupported: [String]? { get }
    var proofTypesSupported: [String: ProofSigningAlgValuesSupported]? { get }
    var display: [CredentialDisplay]? { get }

    func getLocalizedCredentialName(locale: String) -> String
    func getLocalizedClaimName(locale: String, targetClaimName: String) -> String
    func getLocalizedClaimNames(locale: String) -> [String]
    func sortKey(key1: String, key2: String) -> Bool
}

extension CredentialConfiguration {
    func getLocalizedCredentialName(locale: String = "ja-JP") -> String {
        let defaultCredentialDisplay = "Unknown Credential"
        guard let credentialDisplays = self.display, credentialDisplays.count > 0 else {
            return defaultCredentialDisplay
        }
        for d in credentialDisplays {
            if let displayLocale = d.locale {
                if displayLocale == locale {
                    return d.name
                }
            }
        }
        if let firstDisplay = credentialDisplays.first {
            return firstDisplay.name
        }

        return defaultCredentialDisplay
    }
}

typealias ClaimMap = [String: Claim]

extension ClaimMap {
    func getLocalizedClaimName(locale: String, targetClaimName: String) -> String {
        guard let claim = self[targetClaimName] else {
            return targetClaimName
        }

        if let localizedName = claim.getLocalizedClaimName(locale: locale) {
            return localizedName
        }

        if let displays = claim.display, let fallbackDisplay = displays.first {
            return fallbackDisplay.name ?? targetClaimName
        }

        return targetClaimName
    }
    func getLocalizedClaimNames(
        locale: String,
        sortedBy: ((String, String) -> Bool)? = nil
    ) -> [String] {
        var result: [String] = []

        let sortedData: [(String, Claim)]

        if let sortedBy = sortedBy {
            sortedData = self.sorted { sortedBy($0.key, $1.key) }
        }
        else {
            sortedData = Array(self)
        }

        for (claimKey, claimValue) in sortedData {
            if let displays = claimValue.display {
                if displays.isEmpty {
                    result.append(claimKey)
                }
                else {
                    // Priority is given to those matching LOCALE.
                    let firstElmMatchingToLocale = displays.first(where: {
                        ($0.locale == locale) && ($0.name != nil)
                    })
                    if let elm = firstElmMatchingToLocale {
                        result.append(elm.name!)
                    }
                    else {
                        // If there is no match for Locale, use the first element.
                        // And, If `name` does not exist for the first element, `claimKey` is used.
                        let firstDisplay = displays.first!  // `displays` is not empty
                        if let firstDisplayName = firstDisplay.name {
                            result.append(firstDisplayName)
                        }
                        else {
                            result.append(claimKey)
                        }
                    }
                }
            }
            else {
                result.append(claimKey)
            }
        }
        return result
    }
}

struct CredentialSupportedVcSdJwt: CredentialConfiguration {
    let format: String
    let scope: String?
    let cryptographicBindingMethodsSupported: [String]?
    let credentialSigningAlgValuesSupported: [String]?
    let proofTypesSupported: [String: ProofSigningAlgValuesSupported]?
    let display: [CredentialDisplay]?

    let vct: String
    let claims: ClaimMap?
    let order: [String]?

    func sortKey(key1: String, key2: String) -> Bool {
        guard let order = order,
            let leftIndex = order.firstIndex(of: key1),
            let rightIndex = order.firstIndex(of: key2)
        else {
            return key1 < key2
        }
        return leftIndex < rightIndex
    }

    func getLocalizedClaimName(locale: String, targetClaimName: String) -> String {
        guard let claims = self.claims else {
            return targetClaimName
        }
        return claims.getLocalizedClaimName(locale: locale, targetClaimName: targetClaimName)
    }

    func getLocalizedClaimNames(locale: String) -> [String] {
        guard let claims = self.claims else {
            return []
        }

        return claims.getLocalizedClaimNames(
            locale: locale,
            sortedBy: {
                self.sortKey(key1: $0, key2: $1)
            }
        )
    }

}

struct JwtVcJsonCredentialDefinition: Codable {
    let type: [String]
    let credentialSubject: ClaimMap?

    enum CodingKeys: String, CodingKey {
        case type
        case credentialSubject = "credentialSubject"
    }

    func getLocalizedClaimName(locale: String, targetClaimName: String) -> String {
        guard let subject = self.credentialSubject else {
            return targetClaimName
        }
        return subject.getLocalizedClaimName(locale: locale, targetClaimName: targetClaimName)
    }

    func getLocalizedClaimNames(locale: String, sortedBy: ((String, String) -> Bool)? = nil)
        -> [String]
    {
        guard let subject = self.credentialSubject else {
            return []
        }
        return subject.getLocalizedClaimNames(locale: locale, sortedBy: sortedBy)
    }

}

struct CredentialSupportedJwtVcJson: CredentialConfiguration {
    let format: String
    let scope: String?
    let cryptographicBindingMethodsSupported: [String]?
    let credentialSigningAlgValuesSupported: [String]?
    let proofTypesSupported: [String: ProofSigningAlgValuesSupported]?
    let display: [CredentialDisplay]?

    let credentialDefinition: JwtVcJsonCredentialDefinition
    let order: [String]?

    func sortKey(key1: String, key2: String) -> Bool {
        guard let order = order,
            let leftIndex = order.firstIndex(of: key1),
            let rightIndex = order.firstIndex(of: key2)
        else {
            return key1 < key2
        }
        return leftIndex < rightIndex
    }

    func getLocalizedClaimName(locale: String, targetClaimName: String) -> String {
        return self.credentialDefinition.getLocalizedClaimName(
            locale: locale, targetClaimName: targetClaimName)
    }

    func getLocalizedClaimNames(locale: String) -> [String] {
        return self.credentialDefinition.getLocalizedClaimNames(
            locale: locale, sortedBy: { self.sortKey(key1: $0, key2: $1) })
    }
}

struct LdpVcCredentialDefinition: Codable {
    let context: [String]  // todo オブジェクト形式に対応する
    let type: [String]
    let credentialSubject: ClaimMap?

    enum CodingKeys: String, CodingKey {
        case type
        case credentialSubject = "credentialSubject"
        case context = "@context"
    }

    func getClaimName(locale: String, targetClaimName: String) -> String {
        guard let subject = self.credentialSubject else {
            return targetClaimName
        }
        return subject.getLocalizedClaimName(locale: locale, targetClaimName: targetClaimName)
    }

    func getClaimNames(locale: String) -> [String] {
        guard let subject = self.credentialSubject else {
            return []
        }
        return subject.getLocalizedClaimNames(locale: locale)
    }

}

struct CredentialSupportedLdpVc: CredentialConfiguration {
    let format: String
    let scope: String?
    let cryptographicBindingMethodsSupported: [String]?
    let credentialSigningAlgValuesSupported: [String]?
    let proofTypesSupported: [String: ProofSigningAlgValuesSupported]?
    let display: [CredentialDisplay]?

    let credentialDefinition: LdpVcCredentialDefinition
    let order: [String]?

    func sortKey(key1: String, key2: String) -> Bool {
        guard let order = order,
            let leftIndex = order.firstIndex(of: key1),
            let rightIndex = order.firstIndex(of: key2)
        else {
            return key1 < key2
        }
        return leftIndex < rightIndex
    }

    func getLocalizedClaimName(locale: String, targetClaimName: String) -> String {
        return self.credentialDefinition.getClaimName(
            locale: locale, targetClaimName: targetClaimName)
    }

    func getLocalizedClaimNames(locale: String) -> [String] {
        return self.credentialDefinition.getClaimNames(locale: locale)
    }
}

typealias CredentialSupportedJwtVcJsonLd = CredentialSupportedLdpVc

struct CredentialSupportedFormat: Decodable {
    let format: String
}

func sortedClaims(
    _ disclosureDict: [String: String],
    credential: Credential
) -> [(key: String, value: String)] {
    return disclosureDict.sorted(by: { lhs, rhs in
        switch credential.metaData.credentialConfigurationsSupported[credential.credentialType] {
            case let conf as CredentialSupportedVcSdJwt:
                return conf.sortKey(key1: lhs.key, key2: rhs.key)
            case let conf as CredentialSupportedJwtVcJson:
                return conf.sortKey(key1: lhs.key, key2: rhs.key)
            default:
                return lhs.key < rhs.key
        }
    })
}

func decodeCredentialSupported(from jsonData: Data) throws -> CredentialConfiguration {

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    // 一時的なコンテナ構造体をデコードして、formatフィールドを読み取る
    let formatContainer = try decoder.decode(CredentialSupportedFormat.self, from: jsonData)

    print(formatContainer)

    switch formatContainer.format {
        case "vc+sd-jwt":
            return try decoder.decode(CredentialSupportedVcSdJwt.self, from: jsonData)
        case "jwt_vc_json":
            return try decoder.decode(CredentialSupportedJwtVcJson.self, from: jsonData)
        case "ldp_vc":
            return try decoder.decode(CredentialSupportedLdpVc.self, from: jsonData)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Invalid format value"))

    }
}

struct CredentialIssuerMetadata: Codable {
    let credentialIssuer: String
    let authorizationServers: [String]?
    let credentialEndpoint: String
    let batchCredentialEndpoint: String?
    let deferredCredentialEndpoint: String?
    let notificationEndpoint: String?
    let credentialResponseEncryption: CredentialResponseEncryption?
    let credentialIdentifiersSupported: Bool?
    let signedMetadata: String?
    let display: [IssuerDisplay]?
    let credentialConfigurationsSupported: [String: CredentialConfiguration]

    // // It is assumed that the snake case strategy is configured.
    enum CodingKeys: String, CodingKey {
        case credentialIssuer = "credentialIssuer"
        case authorizationServers = "authorizationServers"
        case credentialEndpoint = "credentialEndpoint"
        case batchCredentialEndpoint = "batchCredentialEndpoint"
        case deferredCredentialEndpoint = "deferredCredentialEndpoint"
        case notificationEndpoint = "notificationEndpoint"
        case credentialResponseEncryption = "credentialResponseEncryption"
        case credentialIdentifiersSupported = "credentialIdentifiersSupported"
        case credentialConfigurationsSupported = "credentialConfigurationsSupported"
        case signedMetadata = "signedMetadata"
        case display
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        var credentialsSupportedDict = [String: CredentialConfiguration]()
        let credentialsSupportedContainer = try container.nestedContainer(
            keyedBy: DynamicKey.self, forKey: .credentialConfigurationsSupported)
        for key in credentialsSupportedContainer.allKeys {
            let credentialJSON = try credentialsSupportedContainer.decode(JSON.self, forKey: key)
            let credentialData = try JSONSerialization.data(
                withJSONObject: credentialJSON.object, options: [])
            let credentialSupported = try decodeCredentialSupported(from: credentialData)
            credentialsSupportedDict[key.stringValue] = credentialSupported
        }

        credentialIssuer = try container.decode(String.self, forKey: .credentialIssuer)
        authorizationServers = try container.decodeIfPresent(
            [String].self, forKey: .authorizationServers)
        credentialEndpoint = try container.decodeIfPresent(
            String.self, forKey: .credentialEndpoint)!
        batchCredentialEndpoint = try container.decodeIfPresent(
            String.self, forKey: .batchCredentialEndpoint)
        deferredCredentialEndpoint = try container.decodeIfPresent(
            String.self, forKey: .deferredCredentialEndpoint)
        notificationEndpoint = try container.decodeIfPresent(
            String.self, forKey: .notificationEndpoint)
        credentialResponseEncryption = try container.decodeIfPresent(
            CredentialResponseEncryption.self, forKey: .credentialResponseEncryption)
        credentialIdentifiersSupported = try container.decodeIfPresent(
            Bool.self, forKey: .credentialIdentifiersSupported)
        signedMetadata = try container.decodeIfPresent(
            String.self, forKey: .signedMetadata)
        display = try container.decodeIfPresent([IssuerDisplay].self, forKey: .display)
        credentialConfigurationsSupported = credentialsSupportedDict
    }

    func getCredentialIssuerDisplayName(locale: String = "ja-jp") -> String {
        let defaultIssuerDisplay = "Unknown Issuer"
        guard let issuerDisplays = self.display, issuerDisplays.count > 0 else {
            return defaultIssuerDisplay
        }
        for d in issuerDisplays {
            if let displayLocale = d.locale {
                if let name = d.name, displayLocale == locale {
                    return name
                }
            }
        }
        if let firstDisplay = issuerDisplays.first,
            let name = firstDisplay.name
        {
            return name
        }

        return defaultIssuerDisplay
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(credentialIssuer, forKey: .credentialIssuer)
        try container.encodeIfPresent(authorizationServers, forKey: .authorizationServers)
        try container.encodeIfPresent(credentialEndpoint, forKey: .credentialEndpoint)
        try container.encodeIfPresent(batchCredentialEndpoint, forKey: .batchCredentialEndpoint)
        try container.encodeIfPresent(
            deferredCredentialEndpoint, forKey: .deferredCredentialEndpoint)

        // Encode credentialsSupported based on the actual type
        var credentialsSupportedContainer = container.nestedContainer(
            keyedBy: DynamicKey.self, forKey: .credentialConfigurationsSupported)
        for (key, value) in credentialConfigurationsSupported {
            let credentialEncoder = credentialsSupportedContainer.superEncoder(
                forKey: DynamicKey(stringValue: key)!)
            try value.encode(to: credentialEncoder)
        }

        try container.encodeIfPresent(display, forKey: .display)
    }
}

// DynamicKeyを使って動的なキーを扱う
struct DynamicKey: CodingKey {
    var stringValue: String
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    var intValue: Int?
    init?(intValue: Int) {
        return nil
    }
}
