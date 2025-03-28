//
//  TokenIssuer.swift
//  bunsin_wallet
//
//  Created by 若葉良介 on 2023/12/26.
//

import Foundation

enum VCIClientError: Error {
    case undecodableCredentialOffer(json: String)
    case retrieveMetaDataError(error: MetadataError)
    case tokenEndpointIsRequired
    case credentialEndpointIsRequiredG
    case unsupportedCredentialFormat(format: String)
    case credentialEndpointIsRequired
    case jwtProofRequired
}

struct GrantAuthorizationCode: Codable {
    let issuerState: String?
    let authorizationServer: String?
}

struct TxCode: Codable {
    let inputMode: String?
    let length: Int?
    let description: String?
    enum CodingKeys: String, CodingKey {
        case inputMode = "inputMode"  // It is assumed that the snake case strategy is configured.
        case length, description
    }
}

struct GrantPreAuthorizedCode: Codable {
    let preAuthorizedCode: String
    let txCode: TxCode?
    var interval: Int? = 5
    let authorizationServer: String?

    // It is assumed that the snake case strategy is configured.
    enum CodingKeys: String, CodingKey {
        case preAuthorizedCode = "pre-authorizedCode"
        case txCode = "txCode"
        case authorizationServer = "authorizationServer"
        case interval
    }
}

struct Grant: Codable {
    let authorizationCode: GrantAuthorizationCode?
    let preAuthorizedCode: GrantPreAuthorizedCode?

    // It is assumed that the snake case strategy is configured.
    enum CodingKeys: String, CodingKey {
        case authorizationCode = "authorizationCode"
        case preAuthorizedCode = "urn:ietf:params:oauth:grant-type:pre-authorizedCode"
    }
}

struct CredentialOffer: Codable {
    let credentialIssuer: String
    let credentialConfigurationIds: [String]
    let grants: Grant?

    func isTxCodeRequired() -> Bool {
        if let grants = self.grants,
            let preAuthCodeInfo = grants.preAuthorizedCode,
            let _ = preAuthCodeInfo.txCode
        {
            return true
        }
        else {
            return false
        }
    }

    private static func getCredentialOfferParameter(_ credentialOffer: String) -> String? {
        guard let url = URL(string: credentialOffer),
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems,
            let credentialOfferValue = queryItems.first(where: { $0.name == "credential_offer" })?
                .value
        else {
            return nil
        }

        return credentialOfferValue
    }
    static func fromString(_ credentialOffer: String) -> CredentialOffer? {
        guard let jsonString = getCredentialOfferParameter(credentialOffer),
            let jsonData = jsonString.data(using: .utf8)
        else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(CredentialOffer.self, from: jsonData)
        }
        catch {
            return nil
        }
    }
}

struct OAuthTokenRequest: Codable {
    let grantType: String

    // Defined as mandatory in RFC 6749.
    // However, it is not used in the case of pre-authorized_code.
    let code: String?

    // REQUIRED, if the "redirect_uri" parameter was included
    // in the authorization request
    let redirectUri: String?

    // REQUIRED, if the client is not authenticating
    // with the authorization server
    let clientId: String?

    /* Extension parameters to the Token Request used in the Pre-Authorized Code Flow */

    // This parameter MUST be present
    // if the grant_type is urn:ietf:params:oauth:grant-type:pre-authorized_code
    let preAuthorizedCode: String?
    let txCode: String?

    // It is assumed that the snake case strategy is configured.
    enum CodingKeys: String, CodingKey {
        case code
        case grantType = "grantType"
        case redirectUri = "redirectUri"
        case clientId = "clientId"
        case preAuthorizedCode = "pre-authorizedCode"
        case txCode = "txCode"
    }
}

struct OAuthTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let cNonce: String?
    let cNonceExpiresIn: Int?
}

struct CredentialRequestCredentialResponseEncryption: Codable {

    // todo: Add the JWK property with the appropriate data type.
    // let jwk: ...

    let alg: String
    let enc: String
}

struct LdpVpProofClaim: Codable {
    let domain: String

    // REQUIRED when the Credential Issuer has provided a c_nonce. It MUST NOT be used otherwise
    let challenge: String?
}

struct LdpVp: Codable {
    // todo: improve type definition
    let holder: String
    let proof: [LdpVpProofClaim]
}

protocol Proofable: Codable {
    var proofType: String { get }
}

struct JwtProof: Proofable {
    let proofType: String
    let jwt: String
}

struct CwtProof: Proofable {
    let proofType: String
    let cwt: String
}

struct LdpVpProof: Proofable {
    let proofType: String
    let ldpVp: LdpVp
}

protocol CredentialRequest: Encodable {
    associatedtype ProofType: Proofable
    var format: String { get }
    var proof: ProofType? { get }

    // REQUIRED when credential_identifiers parameter was returned from the Token Response.
    // It MUST NOT be used otherwise
    var credentialIdentifier: String? { get }
    var credentialResponseEncryption: CredentialRequestCredentialResponseEncryption? { get }
}

struct CredentialRequestVcSdJwt: CredentialRequest {
    let format: String
    let proof: JwtProof?
    let credentialIdentifier: String?
    let credentialResponseEncryption: CredentialRequestCredentialResponseEncryption?

    // REQUIRED when the format parameter is present in the Credential Request. It MUST NOT be used otherwise
    let vct: String?
    let claims: [String: Claim]?
}

struct CredentialRequestJwtVcJson: CredentialRequest {
    let format: String
    let proof: JwtProof?
    var credentialIdentifier: String?
    var credentialResponseEncryption: CredentialRequestCredentialResponseEncryption?

    // REQUIRED when the format parameter is present in the Credential Request.
    // It MUST NOT be used otherwise
    let credentialDefinition: CredentialDefinitionJwtVcJson?
}

struct CredentialResponse: Codable {
    let credential: String?  // todo suppoert `ldp_vc`
    let transactionId: String?
    let cNonce: String?
    let cNonceExpiresIn: Int?
    let notificationId: String?
}

struct CredentialDefinitionJwtVcJson: Encodable {
    let type: [String]
    let credentialSubject: [String: ClaimOnlyMandatory]?

    enum CodingKeys: String, CodingKey {
        case type
        case credentialSubject = "credentialSubject"
    }
}

func createCredentialRequest(formatValue: String, credentialType: String, proofable: Proofable?)
    throws -> any CredentialRequest
{
    switch formatValue {
        case "vc+sd-jwt":
            // Proof is optional. Only if present, convert to the appropriate type.
            var proof: JwtProof? = nil
            if let someProof = proofable {
                guard let jwtProof = someProof as? JwtProof else {
                    throw VCIClientError.jwtProofRequired
                }
                proof = jwtProof
            }
            return CredentialRequestVcSdJwt(
                format: formatValue,
                proof: proof,
                credentialIdentifier: nil,
                credentialResponseEncryption: nil,
                vct: credentialType,
                claims: nil
            )
        case "jwt_vc_json":
            // Proof is optional. Only if present, convert to the appropriate type.
            var proof: JwtProof? = nil
            if let someProof = proofable {
                guard let jwtProof = someProof as? JwtProof else {
                    throw VCIClientError.jwtProofRequired
                }
                proof = jwtProof
            }
            return CredentialRequestJwtVcJson(
                format: formatValue,
                proof: proof,
                credentialDefinition:
                    CredentialDefinitionJwtVcJson(
                        type: [credentialType],
                        credentialSubject: nil)
            )
        default:
            throw VCIClientError.unsupportedCredentialFormat(format: formatValue)
    }
}

func postTokenRequest(
    to url: URL, with tokenRequest: OAuthTokenRequest, using session: URLSession = URLSession.shared
) async throws -> OAuthTokenResponse {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    var encoder = URLEncodedFormEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    request.httpBody = try encoder.encode(tokenRequest)

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(OAuthTokenResponse.self, from: data)
}

func postCredentialRequest(
    _ credentialRequest: any CredentialRequest, to url: URL, accessToken: String,
    using session: URLSession = URLSession.shared
) async throws -> CredentialResponse {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

    // CredentialRequestをJSONにエンコード
    // todo: snake_case と camelCaseの混在を適切に扱うようにする
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase

    let encoded = try encoder.encode(credentialRequest)
    var payload: Data? = nil
    if let jsonString = String(data: encoded, encoding: .utf8) {
        // workaround
        let credSubWithCamelCase = jsonString.replacingOccurrences(
            of: "\"credential_subject\"", with: "\"credentialSubject\"")
        payload = credSubWithCamelCase.data(using: .utf8)
        print("JSON String: \(jsonString)")
    }
    else {
        print("Failed to convert Data to String")
    }
    request.httpBody = payload

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }

    // レスポンスデータをデコード
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(CredentialResponse.self, from: data)
}

class VCIClient {

    private var metadata: Metadata
    private var tokenEndpoint: URL
    private var credentialEndpoint: URL
    private(set) var credentialOffer: CredentialOffer

    init(credentialOffer: CredentialOffer, metaData: Metadata) async throws {
        // set `credentialOffer`
        self.credentialOffer = credentialOffer
        // set `metadata`
        self.metadata = metaData
        // set `tokenEndpoint`
        guard let tokenUrlString = metadata.authorizationServerMetadata.tokenEndpoint,
            let tokenUrl = URL(string: tokenUrlString)
        else {
            throw VCIClientError.tokenEndpointIsRequired
        }
        tokenEndpoint = tokenUrl
        // set `credentialEndpoint`
        guard
            let credentialEndpointUrl = URL(
                string: metadata.credentialIssuerMetadata.credentialEndpoint)
        else {
            throw VCIClientError.credentialEndpointIsRequired
        }
        credentialEndpoint = credentialEndpointUrl
    }

    func issueToken(txCode: String?, using session: URLSession = URLSession.shared) async throws
        -> OAuthTokenResponse
    {
        let grants = credentialOffer.grants

        let tokenRequest: OAuthTokenRequest = OAuthTokenRequest(
            grantType: "urn:ietf:params:oauth:grant-type:pre-authorized_code",
            code: nil,
            redirectUri: nil,
            clientId: nil,
            preAuthorizedCode: grants?.preAuthorizedCode?.preAuthorizedCode,
            txCode: txCode
        )

        return try await postTokenRequest(
            to: tokenEndpoint, with: tokenRequest, using: session)
    }

    func issueCredential(
        payload: any CredentialRequest, accessToken: String,
        using session: URLSession = URLSession.shared
    ) async throws -> CredentialResponse {
        return try await postCredentialRequest(
            payload, to: credentialEndpoint, accessToken: accessToken, using: session)
    }
}
