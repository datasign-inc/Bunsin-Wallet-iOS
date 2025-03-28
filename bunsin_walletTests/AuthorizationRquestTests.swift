//
//  AuthorizationRquestTests.swift
//  bunsin_walletTests
//
//  Created by 若葉良介 on 2023/12/29.
//

import JOSESwift
import Security
import XCTest

@testable import bunsin_wallet

final class AuthorizationRquestTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDecodeUriAsJsonWithVariousTypes() {
        let uri =
            "http://example.com?stringParam=hello&intParam=123&boolParam=true&jsonParam=%7B%22key%22%3A%20%22value%22%7D"
        do {
            let result = try decodeUriAsJson(uri: uri)

            XCTAssertEqual(result["stringParam"] as? String, "hello")
            XCTAssertEqual(result["intParam"] as? Int, 123)
            XCTAssertEqual(result["boolParam"] as? Bool, true)
            XCTAssertTrue(result["jsonParam"] is [String: Any])
            XCTAssertEqual((result["jsonParam"] as? [String: Any])?["key"] as? String, "value")
        }
        catch {
            XCTFail("Error occurred: \(error)")
        }
    }

    func testDecodeUriAsJsonWithActualVpUri() {
        let uri =
            "openid4vp:///request?client_id=https%3A%2F%2Fverifier.develop.boolcheck.com%2Fresponses&client_id=https%3A%2F%2Fverifier.develop.boolcheck.com%2Fresponses&nonce=2a330730-75c7-4ed1-b698-b5882c7513ee&state=bfa50883-d752-4092-90a4-89b1b9138d12&response_type=vp_token%20id_token&response_mode=direct_post&client_id_scheme=redirect_uri&response_uri=https%3A%2F%2Fverifier.develop.boolcheck.com%2Fresponses&client_metadata=%7B%22client_id%22%3A%22https%3A%2F%2Fverifier.develop.boolcheck.com%2Fresponses%22%2C%22vp_formats%22%3A%7B%22jwt_vp%22%3A%7B%22alg%22%3A%5B%22ES256%22%5D%7D%7D%2C%22client_name%22%3A%22develop.boolcheck.com%22%2C%22logo_uri%22%3A%22INVALID_CLIENT_METADATA_LOGO_URI%22%2C%22policy_uri%22%3A%22INVALID_CLIENT_METADATA_POLICY_URI%22%2C%22tos_uri%22%3A%22INVALID_CLIENT_METADATA_TOS_URI%22%7D&presentation_definition_uri=https%3A%2F%2Fverifier.develop.boolcheck.com%2Foid4vp%2Fpresentation-definition%3Fid%3Da188f200-dbf0-46a2-9485-fcb5f1591e0f"
        do {
            let result = try decodeUriAsJson(uri: uri)
            XCTAssertEqual(
                result["presentation_definition_uri"] as? String,
                "https://verifier.develop.boolcheck.com/oid4vp/presentation-definition?id=a188f200-dbf0-46a2-9485-fcb5f1591e0f"
            )
        }
        catch {
            XCTFail("Error occurred: \(error)")
        }
    }

    func testUriDecodingAndStructConversion() {
        let url =
            "https://server.example.com/authorize?" + "response_type=code%20id_token"
            + "&client_id=s6BhdRkqt3" + "&redirect_uri=https%3A%2F%2Fclient.example.org%2Fcb"
            + "&response_mode=fragment" + "&scope=openid" + "&state=af0ifjsldkj"
            + "&nonce=n-0S6_WzA2Mj" + "&request=eyJhbGciO"

        do {
            let decodedMap = try decodeUriAsJson(uri: url)
            let payload = try AuthorizationRequestPayloadImpl(from: decodedMap)

            XCTAssertEqual(payload.responseType, "code id_token")
            XCTAssertEqual(payload.clientId, "s6BhdRkqt3")
            XCTAssertEqual(payload.redirectUri, "https://client.example.org/cb")
            XCTAssertEqual(payload.responseMode, ResponseMode.fragment)
            XCTAssertEqual(payload.scope, "openid")
            XCTAssertEqual(payload.state, "af0ifjsldkj")
            XCTAssertEqual(payload.nonce, "n-0S6_WzA2Mj")
            XCTAssertEqual(payload.request, "eyJhbGciO")
        }
        catch {
            XCTFail("Decoding or conversion failed: \(error)")
        }
    }

    func testProcessRequestObject() {
        let testURL = URL(string: "https://example.com/request.jwt")!
        let testJWT =
            "eyJraWQiOiJ0ZXN0LWtpZCIsImFsZyI6IlJTMjU2IiwidHlwIjoiSldUIn0.eyJpc3MiOiJodHRwczovL2NsaWVudC5leGFtcGxlLm9yZy9jYiIsImF1ZCI6Imh0dHBzOi8vc2VydmVyLmV4YW1wbGUuY29tIiwicmVzcG9uc2VfdHlwZSI6ImNvZGUgaWRfdG9rZW4iLCJjbGllbnRfaWQiOiJodHRwczovL2NsaWVudC5leGFtcGxlLm9yZy9jYiIsInJlZGlyZWN0X3VyaSI6Imh0dHBzOi8vY2xpZW50LmV4YW1wbGUub3JnL2NiIiwic2NvcGUiOiJvcGVuaWQiLCJzdGF0ZSI6ImFmMGlmanNsZGtqIiwibm9uY2UiOiJuLTBTNl9XekEyTWoiLCJtYXhfYWdlIjo4NjQwMCwiaWF0IjoxNzAwNDU2MTIwfQ.oQ2EGIC130J0ztO3mN9qpOsQIL6Wowh-2Xd0I-in2LNEybtab7tSNJP4mi58BtkLIVBZGp_BZxk2vSJkSvqTbjnzvaeO3O6mlonjZPQF0-1Af6yB8kHZar2PzggV1ct2RUppndpIFmlTKzSx1jy4diYTrWAAFKcQqlugyRAwlt-VkWBnylkBe6QaetoMCkPPwlz-XYIiJ1lRo8i4N0vt-DY_p89uHnP3R9KeiVzoNDqyNpdooU63DPlfwRSLKw2rYd8UjPxiB-tWKLuPlxz1vR82Lt0X5ofhdN3hUD93c5f15z_88Cj5uYPW9mBVWgueeK0TvzePq40UYUnbaw_z6w"
        let response = HTTPURLResponse(
            url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)!

        MockURLProtocol.mockResponses[testURL.absoluteString] = (
            testJWT.data(using: .utf8), response
        )
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)

        let authorizationRequestPayload = AuthorizationRequestPayloadImpl(
            requestUri: testURL.absoluteString
        )

        runAsyncTest {
            let (_, requestObjectPayload) = try await processRequestObject(
                authorizationRequestPayload, using: mockSession)
            XCTAssertEqual(requestObjectPayload.clientId, "https://client.example.org/cb")
        }
    }

    func testProcessClientMetadata() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)

        let testURL = URL(string: "https://example.com/.well-known/client-metadata.json")!
        guard let url = Bundle.main.url(forResource: "client_metadata", withExtension: "json"),
            let mockData = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read client_metadata.json")
            return
        }
        let response = HTTPURLResponse(
            url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        MockURLProtocol.mockResponses[testURL.absoluteString] = (mockData, response)

        let authorizationRequest = AuthorizationRequestPayloadImpl(
            clientMetadata: nil
        )
        let requestObject = RequestObjectPayloadImpl(
            clientMetadataUri: testURL.absoluteString
        )

        runAsyncTest {
            do {
                let metadata = try await processClientMetadata(
                    authorizationRequest, requestObject, using: mockSession)
                XCTAssertEqual(metadata.jwksUri, "https://example.com/jwks.json")
            }
            catch {
                XCTFail("Request should not fail")
            }
        }
    }

    func testProcessClientMetadataFromQueryParameter() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)

        let testURL = URL(string: "https://example.com/.well-known/client-metadata.json")!
        guard let url = Bundle.main.url(forResource: "client_metadata", withExtension: "json"),
            let mockData = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read client_metadata.json")
            return
        }
        guard let jsonString = String(data: mockData, encoding: .utf8) else {
            XCTFail("Failed to convert JSON data to string")
            return
        }

        do {
            let clientId = "https://client.com"
            guard
                let encodedClientId = clientId.addingPercentEncoding(
                    withAllowedCharacters: .urlQueryAllowed)
            else {
                fatalError("Failed to encode clientId")
            }
            let uri =
                "openid4vp:///vp/auth-request?client_id=\(encodedClientId)&client_metadata=\(jsonString)"
            let (_, authorizationRequest) = try parse(uri: uri)

            runAsyncTest {
                do {
                    let metadata = try await processClientMetadata(
                        authorizationRequest, nil, using: mockSession)
                    XCTAssertEqual(metadata.jwksUri, "https://example.com/jwks.json")
                }
                catch {
                    XCTFail("Request should not fail")
                }
            }
        }
        catch {
            XCTFail("\(error)")
        }
    }

    func testProcessClientMetadataUriFromQueryParameter() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)

        let testURL = URL(string: "https://example.com/.well-known/client-metadata.json")!
        guard let url = Bundle.main.url(forResource: "client_metadata", withExtension: "json"),
            let mockData = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read client_metadata.json")
            return
        }
        let response = HTTPURLResponse(
            url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        MockURLProtocol.mockResponses[testURL.absoluteString] = (mockData, response)

        let authorizationRequest = AuthorizationRequestPayloadImpl(
            clientMetadataUri: testURL.absoluteString
        )

        runAsyncTest {
            do {
                let metadata = try await processClientMetadata(
                    authorizationRequest, nil, using: mockSession)
                XCTAssertEqual(metadata.jwksUri, "https://example.com/jwks.json")
            }
            catch {
                XCTFail("Request should not fail")
            }
        }
    }

    func testPresentationDefinition() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)

        let testURL = URL(string: "https://example.com/presentation_definition.json")!
        guard
            let url = Bundle.main.url(
                forResource: "presentation_definition", withExtension: "json"),
            let mockData = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read presentation_definition.json")
            return
        }
        let response = HTTPURLResponse(
            url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        MockURLProtocol.mockResponses[testURL.absoluteString] = (mockData, response)

        let authorizationRequest = AuthorizationRequestPayloadImpl(
            presentationDefinition: nil
        )
        let requestObject = RequestObjectPayloadImpl(
            presentationDefinitionUri: testURL.absoluteString
        )

        runAsyncTest {
            do {
                let pdOptional = try await processPresentationDefinition(
                    authorizationRequest, requestObject, using: mockSession)
                let pd = try XCTUnwrap(pdOptional, "PresentationDefinition should not be nil.")
                XCTAssertEqual(pd.id, "12345")
            }
            catch {
                XCTFail("Request should not fail. \(error)")
            }
        }
    }

    func testPresentationDefinitionFromQueryParameter() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)

        let testURL = URL(string: "https://example.com/presentation_definition.json")!
        guard
            let url = Bundle.main.url(
                forResource: "presentation_definition", withExtension: "json"),
            let mockData = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read presentation_definition.json")
            return
        }
        let response = HTTPURLResponse(
            url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        MockURLProtocol.mockResponses[testURL.absoluteString] = (mockData, response)

        let authorizationRequest = AuthorizationRequestPayloadImpl(
            presentationDefinitionUri: testURL.absoluteString
        )
        guard let jsonString = String(data: mockData, encoding: .utf8) else {
            XCTFail("Failed to convert JSON data to string")
            return
        }

        let clientId = "https://client.com"
        guard
            let encodedClientId = clientId.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed)
        else {
            fatalError("Failed to encode clientId")
        }
        let uri =
            "openid4vp:///vp/auth-request?client_id=\(encodedClientId)&presentation_definition=\(jsonString)"
        do {
            let (_, authorizationRequest) = try parse(uri: uri)

            runAsyncTest {
                do {
                    let pdOptional = try await processPresentationDefinition(
                        authorizationRequest, nil, using: mockSession)
                    let pd = try XCTUnwrap(pdOptional, "PresentationDefinition should not be nil.")
                    XCTAssertEqual(pd.id, "12345")
                }
                catch {
                    XCTFail("Request should not fail. \(error)")
                }
            }
        }
        catch {
            XCTFail("\(error)")
        }
    }

    func testPresentationDefinitionUriFromQueryParameter() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)

        let testURL = URL(string: "https://example.com/presentation_definition.json")!
        guard
            let url = Bundle.main.url(
                forResource: "presentation_definition", withExtension: "json"),
            let mockData = try? Data(contentsOf: url)
        else {
            XCTFail("Cannot read presentation_definition.json")
            return
        }
        let response = HTTPURLResponse(
            url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        MockURLProtocol.mockResponses[testURL.absoluteString] = (mockData, response)

        let authorizationRequest = AuthorizationRequestPayloadImpl(
            presentationDefinitionUri: testURL.absoluteString
        )

        runAsyncTest {
            do {
                let pdOptional = try await processPresentationDefinition(
                    authorizationRequest, nil, using: mockSession)
                let pd = try XCTUnwrap(pdOptional, "PresentationDefinition should not be nil.")
                XCTAssertEqual(pd.id, "12345")
            }
            catch {
                XCTFail("Request should not fail. \(error)")
            }
        }
    }

    func testFetchAndConvertJWK() async throws {
        // テスト用のJWKセットを用意
        let rsaKeyId = "rsa-key-1"
        let ecKeyId = "ec-key-1"
        guard let jwkSetAndKeyPairs = generateTestJWKSetString(rsaKeyId: rsaKeyId, ecKeyId: ecKeyId)
        else {
            XCTFail("JWKセットの生成に失敗しました")
            return
        }
        let (testJWKSetString, _, _) = jwkSetAndKeyPairs
        let data = Data(testJWKSetString.utf8)

        // URLSessionのモックまたはスタブを作成（省略）
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)

        let testURL = URL(string: "https://example.com/presentation_definition.json")!
        let response = HTTPURLResponse(
            url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)
        MockURLProtocol.mockResponses[testURL.absoluteString] = (data, response)

        // RSA
        var convertedKey = try await fetchAndConvertJWK(
            from: testURL, withKeyId: rsaKeyId, using: mockSession)
        XCTAssertNotNil(convertedKey)

        // EC
        convertedKey = try await fetchAndConvertJWK(
            from: testURL, withKeyId: ecKeyId, using: mockSession)
        XCTAssertNotNil(convertedKey)

        // No Such Key
        convertedKey = try await fetchAndConvertJWK(
            from: testURL, withKeyId: "no-such-key", using: mockSession)
        XCTAssertNil(convertedKey)
    }

    func testExtractKeyIdFromJwt() async throws {
        guard let rsaKeyPair = createRandomRSAKeyPair() else {
            XCTFail("RSA鍵の生成または変換に失敗しました")
            return
        }
        let rsaKeyId = "rsa-key-1"
        guard let jwt = generateTestJWT(kid: rsaKeyId, privateKey: rsaKeyPair.privateKey) else {
            XCTFail("JWTの生成に失敗しました")
            return
        }
        let (header, _, _) = try! JWTUtil.decodeJwt(jwt: jwt)
        let keyId = extractKeyIdFromJwt(header: header)
        XCTAssertEqual(rsaKeyId, keyId)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

func createRandomRSAKeyPair(keySize: Int = 2048) -> KeyPair? {
    let parameters: [String: Any] = [
        kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
        kSecAttrKeySizeInBits as String: keySize,
    ]

    var error: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateRandomKey(parameters as CFDictionary, &error) else {
        print("RSA鍵の生成エラー: \(error!.takeRetainedValue())")
        return nil
    }

    guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
        return nil
    }

    return (publicKey, privateKey)
}

func createRandomECKeyPair(keySize: Int = 256) -> KeyPair? {
    let parameters: [String: Any] = [
        kSecAttrKeyType as String: kSecAttrKeyTypeEC,
        kSecAttrKeySizeInBits as String: keySize,
    ]

    var error: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateRandomKey(parameters as CFDictionary, &error) else {
        print("EC鍵の生成エラー: \(error!.takeRetainedValue())")
        return nil
    }

    guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
        return nil
    }

    return (publicKey, privateKey)
}

func generateTestJWKSetString(rsaKeyId: String, ecKeyId: String) -> (String, KeyPair, KeyPair)? {
    // RSA鍵ペアの生成
    guard let rsaKeyPair = createRandomRSAKeyPair() else {
        print("RSA鍵の生成または変換に失敗しました")
        return nil
    }
    guard let rsaJWK = try? RSAPublicKey(publicKey: rsaKeyPair.publicKey),
        let rsaJWKData = rsaJWK.jsonData(),
        var rsaJWKDict = try? JSONSerialization.jsonObject(with: rsaJWKData) as? [String: Any]
    else {
        print("RSA鍵の生成または変換に失敗しました")
        return nil
    }
    rsaJWKDict["kid"] = rsaKeyId
    let rsaJWKString = (try? rsaJWKDict.toString()) ?? "{}"

    // EC鍵ペアの生成
    guard let ecKeyPair = createRandomECKeyPair() else {
        print("EC鍵の生成または変換に失敗しました")
        return nil
    }
    guard let ecJWK = try? ECPublicKey(publicKey: ecKeyPair.publicKey),
        let ecJWKData = ecJWK.jsonData(),
        var ecJWKDict = try? JSONSerialization.jsonObject(with: ecJWKData) as? [String: Any]
    else {
        print("EC鍵の生成または変換に失敗しました")
        return nil
    }
    ecJWKDict["kid"] = ecKeyId
    let ecJWKString = (try? ecJWKDict.toString()) ?? "{}"

    // JWKセット文字列の生成
    let jwkSetString = """
        {
          "keys": [
            \(rsaJWKString),
            \(ecJWKString)
          ]
        }
        """

    return (jwkSetString, rsaKeyPair, ecKeyPair)
}

func generateTestJWT(kid: String, privateKey: SecKey) -> String? {
    // ヘッダーとペイロードの設定
    var header = JWSHeader(algorithm: .RS512)
    header.kid = kid
    header.typ = "JWT"
    let message = "Summer ⛱, Sun ☀️, Cactus 🌵".data(using: .utf8)!

    let payloadDictionary: [String: Any] = [
        "iss": "issuer", "exp": Int(Date().timeIntervalSince1970 + 3600), "sub": "subject",
    ]

    guard
        let payloadData = try? JSONSerialization.data(
            withJSONObject: payloadDictionary, options: [])
    else {
        print("ペイロードの生成に失敗しました")
        return nil
    }
    let payload = Payload(payloadData)

    // JWTの署名
    let signer = Signer(signingAlgorithm: .RS512, key: privateKey)!
    // let signer = Signer(signingAlgorithm: .RS512, privateKey: privateKey)!
    guard let jws = try? JWS(header: header, payload: payload, signer: signer) else {
        print("jwsの生成に失敗しました")
        return nil
    }

    return jws.compactSerializedString
}
