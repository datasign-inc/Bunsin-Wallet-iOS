//
//  JWT.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/01/05.
//

import ASN1Decoder
import CryptoKit
import Foundation
import JWTDecode
import SwiftASN1
import X509

enum SignatureError: Error {
    case UnsupportedAlgorithmError
    case UnableToCreateSignatureError
    case VoidContentError
    case SigningKeyNotFound
}

enum JWTVerificationError: Error {
    case unsupportedAlgorithm
    case invalidPublicKeyType
    case verificationFailed(String)
}

// See https://swiftpackageindex.com/apple/swift-asn1/main/documentation/swiftasn1/decodingasn1#Final-Result
struct ECDSASignature: DERImplicitlyTaggable {
    static var defaultIdentifier: SwiftASN1.ASN1Identifier {
        .sequence
    }
    var r: ArraySlice<UInt8>
    var s: ArraySlice<UInt8>
    init(r: ArraySlice<UInt8>, s: ArraySlice<UInt8>) {
        self.r = r
        self.s = s
    }
    init(derEncoded rootNode: ASN1Node, withIdentifier identifier: SwiftASN1.ASN1Identifier) throws
    {
        self = try DER.sequence(rootNode, identifier: identifier) { nodes in
            let r = try ArraySlice<UInt8>(derEncoded: &nodes)
            let s = try ArraySlice<UInt8>(derEncoded: &nodes)
            return ECDSASignature(r: r, s: s)
        }
    }
    func serialize(
        into coder: inout DER.Serializer, withIdentifier identifier: SwiftASN1.ASN1Identifier
    ) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            try coder.serialize(self.r)
            try coder.serialize(self.s)
        }
    }
}

func convertRstoDer(r: Data, s: Data) -> Data? {
    let rArray = [UInt8](r)[...]
    let sArray = [UInt8](s)[...]
    let signature = ECDSASignature(r: rArray, s: sArray)
    var serializer = DER.Serializer()
    do {
        // ECDSASignature の serialize メソッドを呼び出して DER 形式にシリアライズ
        try signature.serialize(into: &serializer, withIdentifier: .sequence)
        let bytes = serializer.serializedBytes
        return Data(bytes)
    }
    catch {
        return nil
    }
}

enum JWTUtil {

    static func sign(keyAlias: String, header: [String: Any], payload: [String: Any])
        -> Result<String, SignatureError>
    {
        guard let privateKey = KeyPairUtil.getPrivateKey(alias: keyAlias) else {
            return .failure(SignatureError.SigningKeyNotFound)
        }

        guard
            let h = try? header.toBase64UrlString(),
            let p = try? payload.toBase64UrlString()
        else {
            return .failure(SignatureError.VoidContentError)
        }

        let tbsContent = (h + "." + p).data(using: .utf8)
        let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA256

        guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
            return .failure(SignatureError.UnsupportedAlgorithmError)
        }

        var error: Unmanaged<CFError>?
        guard
            let signature = SecKeyCreateSignature(
                privateKey,
                algorithm,
                tbsContent! as CFData,
                &error) as Data?
        else {
            return .failure(SignatureError.UnableToCreateSignatureError)
        }

        do {
            let asn1Object = try ASN1DERDecoder.decode(data: signature)
            assert(asn1Object.count == 1)
            let sequence = asn1Object[0]
            assert(sequence.subCount() == 2)

            guard let firstElm = sequence.sub(0)?.value as? Data,
                let secondElm = sequence.sub(1)?.value as? Data
            else {
                return .failure(SignatureError.UnableToCreateSignatureError)
            }

            let combined = firstElm + secondElm
            let jwt =
                String(data: tbsContent!, encoding: .utf8)! + "."
                + combined.base64URLEncodedString()

            return .success(jwt)
        }
        catch {
            return .failure(SignatureError.UnableToCreateSignatureError)
        }
    }

    static func verifyJwt(jwt: String, publicKey: SecKey) -> Result<
        JWT, JWTVerificationError
    > {
        let parts = jwt.components(separatedBy: ".")
        if parts.count != 3 {
            return .failure(.verificationFailed("Malformed jwt"))
        }

        guard let decodedJwt = try? decode(jwt: jwt),
            let algorithm = decodedJwt.header["alg"],
            let signatureAlg = getAlgorithm(publicKey: publicKey, algorithm: algorithm as! String)
        else {
            return .failure(.verificationFailed("Failed to decode JWT"))
        }

        guard let tbsContent = (parts[0] + "." + parts[1]).data(using: .ascii),
            let signature = parts[2].data(using: .ascii),
            let signatureBytes = Data(base64URLEncoded: signature)
        else {
            return .failure(.verificationFailed("Malformed JWT"))
        }

        let halfIndex = signatureBytes.count / 2
        let r = signatureBytes.prefix(upTo: halfIndex)
        let s = signatureBytes.suffix(from: halfIndex)
        guard let derSignature = convertRstoDer(r: Data(r), s: Data(s)) else {
            return .failure(.verificationFailed("Unable to convert signature to der format"))
        }

        let result = SecKeyVerifySignature(
            publicKey, signatureAlg, tbsContent as CFData, derSignature as CFData, nil)
        if result {
            return .success(decodedJwt)
        }
        else {
            return .failure(
                JWTVerificationError.verificationFailed("result of SecKeyVerifySignature is false"))
        }
    }

    typealias VerifiedX5CJwt = (decoded: JWT, certs: [Certificate])
    static func verifyJwtByX5C(jwt: String, verifyCertChain: Bool = true) -> Result<
        VerifiedX5CJwt, JWTVerificationError
    > {
        guard let decodedJwt = try? decode(jwt: jwt) else {
            return .failure(.verificationFailed("Unable to decode jwt"))
        }

        guard let x5c = decodedJwt.header["x5c"] as? [String] else {
            return .failure(.verificationFailed("Unable to get x5c property"))
        }
        guard let certificates = try? SignatureUtil.convertPemToX509Certificates(pemChain: x5c)
        else {
            return .failure(.verificationFailed("Unable to convert x5c"))
        }

        let firstCert = certificates[0]
        let subjectPublicKeyInfoBytes = firstCert.publicKey.subjectPublicKeyInfoBytes
        let publicKeyData = Data(subjectPublicKeyInfoBytes)
        // CFDataにキャスト
        let publicKeyCFData = publicKeyData as CFData

        var error: Unmanaged<CFError>?
        guard
            let secKey = SecKeyCreateWithData(
                publicKeyCFData,
                [
                    kSecAttrKeyType: kSecAttrKeyTypeEC,
                    kSecAttrKeyClass: kSecAttrKeyClassPublic,
                ] as CFDictionary, &error)
        else {
            return .failure(.verificationFailed("Unable to Convert Public Key"))
        }

        let jwtValidation = JWTUtil.verifyJwt(jwt: jwt, publicKey: secKey)
        if case .success = jwtValidation {
            if verifyCertChain {
                let chainValidaton = try! SignatureUtil.validateCertificateChain(
                    certificates: certificates
                )
                if !chainValidaton {
                    return .failure(.verificationFailed("Unable to verify chain of trust"))
                }
            }
            else {
                print("Skip ValidateCertificateChain!!!")
            }
            return .success((decodedJwt, certificates))
        }

        return .failure(.verificationFailed("Unable to verify jwt"))
    }

    static func verifyJwtByX5U(jwt: String) -> Result<JWT, JWTVerificationError> {
        guard let decodedJwt = try? decode(jwt: jwt) else {
            return .failure(.verificationFailed("Unable to decode jwt"))
        }

        guard let x5uUrl = decodedJwt.header["x5u"] as? String else {
            return .failure(.verificationFailed("Unable to get x5u url"))
        }
        print("x5u url: \(x5uUrl)")
        guard let certificates = SignatureUtil.getX509CertificatesFromUrl(url: x5uUrl) else {
            return .failure(.verificationFailed("Unable to get x5u"))
        }

        let firstCert = certificates[0]
        let subjectPublicKeyInfoBytes = firstCert.publicKey.subjectPublicKeyInfoBytes
        let publicKeyData = Data(subjectPublicKeyInfoBytes)
        // CFDataにキャスト
        let publicKeyCFData = publicKeyData as CFData

        var error: Unmanaged<CFError>?
        guard
            let secKey = SecKeyCreateWithData(
                publicKeyCFData,
                [
                    kSecAttrKeyType: kSecAttrKeyTypeEC,
                    kSecAttrKeyClass: kSecAttrKeyClassPublic,
                ] as CFDictionary, &error)
        else {
            return .failure(.verificationFailed("Unable to Convert Public Key"))
        }

        let chainValidaton = try! SignatureUtil.validateCertificateChain(certificates: certificates)
        if !chainValidaton {
            return .failure(.verificationFailed("Unable to verify chain of trust"))
        }

        let jwtValidation = JWTUtil.verifyJwt(jwt: jwt, publicKey: secKey)
        if case .success = jwtValidation {
            return .success(decodedJwt)
        }

        return .failure(.verificationFailed("Unable to verify jwt"))
    }

    static func decodeJwt(jwt: String) throws -> ([String: Any], [String: Any], String?) {
        let decodedJwt = try decode(jwt: jwt)
        return (decodedJwt.header, decodedJwt.body, decodedJwt.signature)
    }
}

func getAlgorithm(publicKey: SecKey, algorithm: String) -> SecKeyAlgorithm? {
    switch publicKeyType(publicKey) {
        case .rsa:
            switch algorithm {
                case "RS256":
                    return .rsaSignatureMessagePKCS1v15SHA256
                case "RS384":
                    return .rsaSignatureMessagePKCS1v15SHA384
                case "RS512":
                    return .rsaSignatureMessagePKCS1v15SHA512
                default:
                    return nil
            }

        case .ec:
            switch algorithm {
                case "ES256":
                    return .ecdsaSignatureMessageX962SHA256
                case "ES384":
                    return .ecdsaSignatureMessageX962SHA384
                case "ES512":
                    return .ecdsaSignatureMessageX962SHA512
                default:
                    return nil
            }
        default:
            return nil
    }
}

enum PublicKeyType {
    case rsa
    case ec
    case other

    init(_ key: SecKey) {
        guard let attributes = SecKeyCopyAttributes(key) as? [String: Any],
            let keyClass = attributes[kSecAttrKeyClass as String] as? String
        else {
            self = .other
            return
        }

        switch keyClass {
            case String(kSecAttrKeyClassPublic):
                if let algorithm = attributes[kSecAttrKeyType as String] as? String {
                    if algorithm == String(kSecAttrKeyTypeRSA) {
                        self = .rsa
                    }
                    else if algorithm == String(kSecAttrKeyTypeEC) {
                        self = .ec
                    }
                    else {
                        self = .other
                    }
                }
                else {
                    self = .other
                }
            default:
                self = .other
        }
    }
}

func publicKeyType(_ key: SecKey) -> PublicKeyType {
    return PublicKeyType(key)
}
