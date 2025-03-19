//
//  OpenIdProvider.swift
//  bunsin_wallet
//
//  Created by 若葉良介 on 2024/01/03.
//

import Foundation
import JOSESwift

extension String {
    var isOpenIdCredentialOffer: Bool {
        self.hasPrefix("openid-credential-offer://")
    }
    var isOpenId4VP: Bool {
        self.hasPrefix("openid4vp://")
    }
    var isSiopv2: Bool {
        self.hasPrefix("siopv2://")
    }
}

class NoRedirectDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession, task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        // リダイレクトを停止する
        completionHandler(nil)
    }
}

class OpenIdProvider {
    private var option: ProviderOption
    private var secp256k1KeyPair: KeyPairData?  // for sub of id_token
    private var keyBinding: KeyBinding?
    private var jwtVpJsonGenerator: JwtVpJsonGenerator?
    var authRequestProcessedData: ProcessedRequestData?
    var clientId: String?
    var responseType: String?
    var responseMode: ResponseMode?
    var nonce: String?
    var state: String?
    var redirectUri: String?
    var responseUri: String?
    var presentationDefinition: PresentationDefinition?

    init(_ option: ProviderOption) {
        self.option = option
    }

    func setSecp256k1KeyPair(keyPair: KeyPairData) {
        self.secp256k1KeyPair = keyPair
    }

    func setKeyBinding(keyBinding: KeyBinding) {
        self.keyBinding = keyBinding
    }

    func setJwtVpJsonGenerator(jwtVpJsonGenerator: JwtVpJsonGenerator) {
        self.jwtVpJsonGenerator = jwtVpJsonGenerator
    }

    func processAuthRequest(_ url: String, using session: URLSession = URLSession.shared) async
        -> Result<ProcessedRequestData, AuthorizationRequestError>
    {
        print("parseAndResolve")
        let processedRequestDataResult = await parseAndResolve(from: url)
        switch processedRequestDataResult {
            case .success(let processedRequestData):
                let authRequest = processedRequestData.authorizationRequest
                let requestObj = processedRequestData.requestObject
                guard let _clientId = authRequest.clientId else {
                    return .failure(
                        .authRequestInputError(
                            reason: .compliantError(reason: "can not get client id")))
                }
                clientId = _clientId

                if processedRequestData.requestIsSigned {
                    print("verify request jwt")
                    let clientScheme = requestObj!.clientIdScheme
                    let jwt = processedRequestData.requestObjectJwt
                    if clientScheme == "x509_san_dns" {
                        let result = JWTUtil.verifyJwtByX5C(jwt: jwt)
                        switch result {
                            case .success(let verifedX5CJwt):
                                print("verify request jwt success")
                                // https://openid.net/specs/openid-4-verifiable-presentations-1_0.html
                                /*
                            the Client Identifier MUST be a DNS name and match a dNSName Subject Alternative Name (SAN) [RFC5280] entry in the leaf certificate passed with the request.
                             */
                                let (decoded, certificates) = verifedX5CJwt

                                guard let url = URL(string: _clientId),
                                    let domainName = url.host
                                else {
                                    return .failure(
                                        .authRequestInputError(
                                            reason: .compliantError(
                                                reason: "Unable to get host name")))
                                }

                                if isDomainInSAN(certificate: certificates[0], domain: domainName) {
                                    print("verify san entry success")
                                }
                                else {
                                    return .failure(
                                        .authRequestInputError(
                                            reason: .compliantError(
                                                reason: "Invalid client_id not in san entry of cert"
                                            )
                                        ))
                                }

                                if let urlString = requestObj?.responseUri
                                    ?? requestObj?.redirectUri,
                                    let url = URL(string: urlString)
                                {
                                    if let clientUrl = URL(string: _clientId),
                                        let urlHost = url.host, let clientIdHost = clientUrl.host,
                                        urlHost == clientIdHost
                                    {

                                        print("verify client_id and url success")
                                    }
                                    else {
                                        return .failure(
                                            .authRequestInputError(
                                                reason: .compliantError(
                                                    reason:
                                                        "Invalid client_id or response_uri(redirect_uri)"
                                                )
                                            ))
                                    }
                                }

                            case .failure(let error):
                                print("\(error)")
                                return .failure(
                                    .authRequestInputError(
                                        reason: .compliantError(
                                            reason: "Invalid client_id or response_uri")
                                    ))
                        }
                    }
                    else {
                        let clientMetadata = processedRequestData.clientMetadata
                        let result = await verifyRequestObject(
                            jwt: jwt, clientMetadata: clientMetadata)
                        switch result {
                            case .success:
                                print("verify request jwt success")
                            case .failure(let error):
                                return .failure(error)
                        }
                    }
                }

                // https://openid.net/specs/openid-4-verifiable-presentations-1_0-ID2.html#section-5
                // response_mode:
                // OPTIONAL. Defined in [OAuth.Responses]. This parameter is used (through the new Response Mode direct_post) to ask the Wallet to send the response to the Verifier via an HTTPS connection (see Section 6.2 for more details). It is also used to request signing and encrypting (see Section 6.3 for more details). If the parameter is not present, the default value is fragment.
                if let _responseMode = requestObj?.responseMode ?? authRequest.responseMode {
                    responseMode = _responseMode
                }
                else {
                    responseMode = ResponseMode.fragment
                }

                // https://openid.net/specs/openid-4-verifiable-presentations-1_0-ID2.html#section-6.2
                // When the response_uri parameter is present, the redirect_uri Authorization Request parameter MUST NOT be present.
                var workaroundForSiopv2: String? = nil
                if let response = requestObj?.responseUri ?? authRequest.responseUri,
                    let redirect = requestObj?.redirectUri ?? authRequest.redirectUri
                {
                    return .failure(
                        .authRequestInputError(
                            reason: .compliantError(
                                reason:
                                    "response_uri and redirect_uri MUST NOT exist at the same time."
                            )))
                }
                // If the redirect_uri Authorization Request parameter is present when the Response Mode is direct_post, the Wallet MUST return an invalid_request
                if responseMode == .directPost,
                    let redirect = requestObj?.redirectUri ?? authRequest.redirectUri
                {
                    // workaround
                    // SIOPv2では、response_uriが定義されていない。
                    // これは明らかに仕様上定義されるべきなので、その対応が行われるまでSIOPv2の場合はredirectUriをresponseUriに読み替える
                    if url.isSiopv2 {
                        workaroundForSiopv2 = redirect
                    }
                    else {
                        return .failure(
                            .authRequestInputError(
                                reason: .compliantError(
                                    reason:
                                        "invalid_request: If responseMode is directPost, redirectUri must not be present."
                                )
                            )
                        )
                    }
                }

                if responseMode == ResponseMode.directPost
                    || responseMode == ResponseMode.directPostJwt
                    || responseMode == ResponseMode.post
                {
                    guard
                        let _responseUri = requestObj?.responseUri ?? authRequest.responseUri
                            ?? workaroundForSiopv2
                    else {
                        return .failure(
                            .authRequestInputError(
                                reason: .compliantError(reason: "can not get response uri")))
                    }
                    responseUri = _responseUri
                }
                else {
                    guard let _redirectUri = requestObj?.redirectUri ?? authRequest.redirectUri
                    else {
                        return .failure(
                            .authRequestInputError(
                                reason: .compliantError(reason: "can not get redirect uri")))
                    }
                    redirectUri = _redirectUri
                }

                // https://openid.net/specs/openid-4-verifiable-presentations-1_0-ID2.html#section-9.1
                // If omitted, the default value is pre-registered
                let clientScheme =
                    requestObj?.clientIdScheme ?? authRequest.clientIdScheme ?? "pre-registered"

            
                /*
                 ID2の仕様に則ると、以下のチェックを実装することとなる。
                 このチェック仕様は、direct_post 且つ redirect_uri が存在する場合 を想定している。
                 上記実装で既にチェックしている通り、 direct_postの場合に redirect_uri が存在することはあってはならない。
                 このチェックが真になることはありえない。ID3でもこのチェックに関する記載は無くなっているので、コメントアウトしている。

                // https://openid.net/specs/openid-4-verifiable-presentations-1_0-ID2.html#section-6.2
                // Note: If the Client Identifier scheme redirect_uri is used in conjunction with the Response Mode direct_post,
                // and the redirect_uri parameter is present, the client_id value MUST be equal to the response_uri value.
                if clientScheme == "redirect_uri" && responseMode == .directPost {
                    if (redirectUri != nil) && (clientId != responseUri) {
                        print(
                            "`clientId` \(String(describing: clientId)) must equal responseUri \(String(describing: responseUri))"
                        )
                        return .failure(
                            .authRequestInputError(
                                reason: .compliantError(reason: "Invalid client_id or response_uri")
                            ))
                    }
                }
                */
            

                guard let _responseType = requestObj?.responseType ?? authRequest.responseType
                else {
                    return .failure(
                        .authRequestInputError(
                            reason: .compliantError(reason: "can not get response type")))
                }
                responseType = _responseType

                guard let _nonce = requestObj?.nonce ?? authRequest.nonce else {
                    return .failure(
                        .authRequestInputError(reason: .compliantError(reason: "can not get nonce"))
                    )
                }
                nonce = _nonce
                state = requestObj?.state ?? authRequest.state ?? ""
                if _responseType.contains("vp_token") {
                    guard let _presentationDefinition = processedRequestData.presentationDefinition
                    else {
                        print("processed request data : \(processedRequestData)")
                        return .failure(
                            .authRequestInputError(
                                reason: .compliantError(
                                    reason: "can not get presentation definition")))
                    }
                    presentationDefinition = _presentationDefinition
                }
                self.authRequestProcessedData = processedRequestData
                return .success(processedRequestData)
            case .failure(let error):
                return .failure(error)
        }
    }

    func respondToken(
        credentials: [SubmissionCredential]?,
        using session: URLSession = URLSession.shared
    ) async -> Result<
        TokenSendResult, Error
    > {
        guard let responseType = responseType else {
            print("responseType is not setup")
            return .failure(OpenIdProviderIllegalStateException.illegalResponseTypeState)
        }

        guard let responseMode = responseMode else {
            return .failure(OpenIdProviderIllegalStateException.illegalResponseModeState)
        }

        let requireIdToken = responseType.contains("id_token")
        let requireVpToken = responseType.contains("vp_token")

        if !requireIdToken && !requireVpToken {
            print("Both or either `id_token` and `vp_token` are required.")
            return .failure(OpenIdProviderIllegalStateException.illegalResponseTypeState)
        }

        var idTokenFormData: [String: String]? = nil
        var vpTokenFormData: [String: String]? = nil

        var idTokenForHistory: String? = nil
        var vpForHistory: [SharedCredential]? = nil

        if requireIdToken {
            let created = createSiopIdToken()
            switch created {
                case .success(let (successData, rawIdToken)):
                    idTokenFormData = successData
                    idTokenForHistory = rawIdToken
                case .failure(let errorData):
                    return .failure(errorData)
            }
        }
        if requireVpToken {
            guard let creds = credentials else {
                return .failure(OpenIdProviderIllegalInputException.illegalCredentialInput)
            }
            let created = createVpToken(credentials: creds)
            switch created {
                case .success(let (successData, sharedCredentials)):
                    vpTokenFormData = successData
                    vpForHistory = sharedCredentials
                case .failure(let errorData):
                    return .failure(errorData)
            }
        }

        var mergedFormData = (idTokenFormData ?? [:]).merging(vpTokenFormData ?? [:]) { (_, new) in
            new
        }
        
        if let state = state {
            mergedFormData["state"] = state
        }

        var uri: String? = nil
        switch responseMode {
            case .directPost, .directPostJwt, .post:
                uri = responseUri
            default:
                uri = redirectUri
        }
        guard let whereToRespond = uri else {
            return .failure(OpenIdProviderIllegalStateException.illegalRedirectUriState)
        }

        do {
            let (data, httpResponse, uri) = try await sendFormData(
                formData: mergedFormData,
                url: URL(string: whereToRespond)!,
                responseMode: responseMode,
                using: session
            )

            let (statusCode, location, cookies) = try convertVerifierResponse(
                data: data, response: httpResponse, requestURL: uri)

            print("status code: \(statusCode)")
            return .success(
                TokenSendResult(
                    statusCode: statusCode, location: location, cookies: cookies,
                    sharedIdToken: idTokenForHistory,
                    sharedCredentials: vpForHistory))
        }
        catch {
            return .failure(error)
        }

    }

    func createSiopIdToken() -> Result<([String: String], String), Error> {
        guard let authRequestProcessedData = self.authRequestProcessedData else {
            return .failure(
                OpenIdProviderIllegalStateException.illegalAuthRequestProcessedDataState)
        }
        let authRequest = authRequestProcessedData.authorizationRequest
        let requestObj = authRequestProcessedData.requestObject
        guard let clientId = requestObj?.clientId ?? authRequest.clientId else {
            return .failure(OpenIdProviderIllegalStateException.illegalClientIdState)
        }
        guard let nonce = requestObj?.nonce ?? authRequest.nonce else {
            return .failure(OpenIdProviderIllegalStateException.illegalNonceState)
        }

        // TODO: ProviderOptionのアルゴリズムで分岐可能にする
        guard let keyPair = secp256k1KeyPair else {
            return .failure(OpenIdProviderIllegalStateException.illegalKeypairState)
        }
        let x = keyPair.publicKey.0.base64URLEncodedString()
        let y = keyPair.publicKey.1.base64URLEncodedString()
        let jwk = ECPublicJwk(kty: "EC", crv: "secp256k1", x: x, y: y)
        guard let jwkThumbprint = SignatureUtil.toJwkThumbprint(jwk: jwk) else {
            return .failure(OpenIdProviderIllegalStateException.illegalJwkThumbprintState)
        }

        let prefix = "urn:ietf:params:oauth:jwk-thumbprint:sha-256"
        let sub = "\(prefix):\(jwkThumbprint)"
        let currentMilliseconds = Int64(Date().timeIntervalSince1970 * 1000)

        let idTokenPayload = IDTokenPayloadImpl(
            iss: sub,
            sub: sub,
            aud: clientId,
            iat: currentMilliseconds / 1000,
            exp: (currentMilliseconds / 1000) + option.expiresIn,
            nonce: nonce,
            subJwk: [
                "crv": jwk.crv,
                "kty": jwk.kty,
                "x": jwk.x,
                "y": jwk.y,
            ]
        )
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let jsonData = try encoder.encode(idTokenPayload)
            let payload = String(data: jsonData, encoding: .utf8)!
            let idToken = try ES256K.createJws(key: keyPair.privateKey, payload: payload)
            let formData = ["id_token": idToken]

            return .success((formData, idToken))
        }
        catch {
            return .failure(error)
        }
    }

    func createVpToken(
        credentials: [SubmissionCredential],
        using session: URLSession = URLSession.shared
    ) -> Result<([String: String], [SharedCredential]), Error> {

        guard let clientId = clientId,
            let responseMode = responseMode,
            let nonce = nonce,
            let presentationDefinition = presentationDefinition
        else {
            return .failure(OpenIdProviderIllegalStateException.illegalState)
        }

        let isMultipleVpTokens = credentials.count > 1
        let preparedSubmissionData = try! credentials.enumerated().compactMap {
            (index, credential) -> PreparedSubmissionData? in
            let tokenIndex = isMultipleVpTokens ? index : index - 1
            switch credential.format {
                case "vc+sd-jwt":
                    return
                        try credential.createVpTokenForSdJwtVc(
                            clientId: clientId,
                            nonce: nonce,
                            tokenIndex: tokenIndex,
                            keyBinding: keyBinding)

                case "jwt_vc_json":
                    return
                        try credential.createVpTokenForJwtVc(
                            clientId: clientId,
                            nonce: nonce,
                            tokenIndex: tokenIndex,
                            jwtVpJsonGenerator: jwtVpJsonGenerator

                        )

                default:
                    throw IllegalArgumentException.badParams
            }
        }

        guard let vpTokenValue = conformToFormData(preparedData: preparedSubmissionData) else {
            return .failure(OpenIdProviderIllegalStateException.illegalJsonState)
        }

        let presentationSubmission = PresentationSubmission(
            id: UUID().uuidString,
            definitionId: presentationDefinition.id,
            descriptorMap: preparedSubmissionData.map { $0.descriptorMap }
        )

        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase

        // オブジェクトをJSON文字列にエンコード
        let jsonData = try! jsonEncoder.encode(presentationSubmission)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        let sharedCredentials = preparedSubmissionData.map {
            SharedCredential(
                id: $0.credentialId,
                purposeForSharing: $0.purpose,
                sharedClaims: $0.disclosedClaims)
        }

        var formData = ["vp_token": vpTokenValue, "presentation_submission": jsonString]

        return .success((formData, sharedCredentials))
    }

    func convertVerifierResponse(data: Data, response: HTTPURLResponse, requestURL: URL)
        throws -> (Int, String?, [String]?)
    {
        let statusCode = response.statusCode
        if statusCode == 200 {
            if let contentType = response.allHeaderFields["Content-Type"] as? String {
                if contentType.hasPrefix("application/json") {
                    guard
                        let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                        let jsonDict = jsonObject as? [String: Any]
                    else {
                        throw AuthorizationError.invalidData
                    }
                    let location = jsonDict["redirect_uri"] as? String
                    return (statusCode, location, nil)
                }
            }
        }
        return (statusCode, nil, nil)
    }
}
