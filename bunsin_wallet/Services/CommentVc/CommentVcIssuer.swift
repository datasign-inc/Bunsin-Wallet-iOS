//
//  CommentVcIssuer.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/10/15.
//

import Foundation

class CommentVcIssuer {
    private let keyAlias: String

    init(keyAlias: String) {
        self.keyAlias = keyAlias

        if !KeyPairUtil.isKeyPairExist(alias: self.keyAlias) {
            print("Generating Key \(self.keyAlias) for Comment signing")
            do {
                try KeyPairUtil.generateSignVerifyKeyPair(alias: self.keyAlias)
            }
            catch {
                fatalError("Failed to generate key pair: \(error)")
            }
        }
    }

    func issueCredential(
        url: String,
        comment: String,
        contentTruth: ContentTruth
    ) -> Credential {
        let issuerPublicKey = self.getJwk()

        guard let kty = issuerPublicKey["kty"],
            let crv = issuerPublicKey["crv"],
            let x = issuerPublicKey["x"],
            let y = issuerPublicKey["y"]
        else {
            fatalError("unable to get comment issuer's public key")
        }

        // todo: コメントクレデンシャルのissが公開鍵のthumbprintでよいかどうかは、別途要確認.
        // とりあえず、何かの値を設定するために、thumbprintを仮で設定しておく.
        guard
            let iss = SignatureUtil.toJwkThumbprint(
                jwk: ECPublicJwk(kty: kty, crv: crv, x: x, y: y))
        else {
            fatalError("unable to convert to jwk thumbprint")
        }

        let currentTimeSeconds = Int64(Date().timeIntervalSince1970)
        let comment = Comment(url: url, comment: comment, boolValue: contentTruth)
        let jwt = self.generateJwt(
            comment: comment,
            headerOptions: CommentVcHeaderOptions(),
            payloadOptions: CommentVcPayloadOptions(iss: iss, nbf: currentTimeSeconds))

        var credential = Datastore_CredentialData()
        credential.id = UUID().uuidString
        credential.format = "jwt_vc_json"
        credential.credential = jwt
        credential.iss = iss
        credential.iat = currentTimeSeconds
        credential.type = Constants.VC.CommentVC.COMMENT_VC_TYPE_VALUE

        credential.exp = currentTimeSeconds + 86400 * 365

        credential.cNonce = ""
        credential.cNonceExpiresIn = 3600
        credential.accessToken = ""
        credential.credentialIssuerMetadata = """
            {
                    "credential_issuer": "https://self-issued.boolcheck.com/\(iss)",
                    "credential_endpoint": "https://self-issued.boolcheck.com/\(iss)",
                    "display": [{
                         "name": "Boolcheck Comment VC Issuer",
                         "locale": "en-US",
                         "logo": {
                            "uri": "https://boolcheck.com/public/issuer-logo.png",
                            "alt_text": "a square logo of a comment credential issuer"
                         }
                        }],
                    "credential_configurations_supported": {
                      "\(Constants.VC.CommentVC.COMMENT_VC_TYPE_VALUE)": {
                        "format": "jwt_vc_json",
                        "credential_definition": {
                          "type": [
                            "\(Constants.VC.CommentVC.COMMENT_VC_TYPE_VALUE)",
                            "VerifiableCredential"
                          ],
                          "credentialSubject": {
                            "url": {
                              "display": [
                                {
                                  "name": "Url",
                                  "locale": "en-US"
                                },
                                {
                                  "name": "Url",
                                  "locale": "ja-JP"
                                }
                              ]
                            },
                            "comment": {
                              "display": [
                                {
                                  "name": "Comment",
                                  "locale": "en-US"
                                },
                                {
                                  "name": "コメント",
                                  "locale": "ja-JP"
                                }
                              ]
                            },
                            "bool_value": {
                              "display": [
                                {
                                  "name": "真偽値",
                                  "locale": "ja-JP"
                                }
                              ]
                            }
                          }
                        },
                        "display": [
                          {
                            "name": "\(Constants.VC.CommentVC.COMMENT_VC_TYPE_VALUE)",
                            "locale": "ja_JP",
                            "logo": {
                              "uri": "https://boolcheck.com/public/credential-logo.png",
                              "alt_text": "a square logo of a credential"
                            },
                            "background_color": "#12107c",
                            "text_color": "#FFFFFF"
                          }
                        ]
                      }
                    }
                  }
            """
        return credential.toCredential()!

    }

    func generateJwt(
        comment: Comment,
        headerOptions: CommentVcHeaderOptions,
        payloadOptions: CommentVcPayloadOptions
    ) -> String {

        let header: [String: Any] = [
            "alg": headerOptions.alg,
            "typ": headerOptions.typ,
            "jwk": getJwk(),
        ]

        let payload: [String: Any] = [
            "iss": payloadOptions.iss,
            "sub": payloadOptions.iss,
            "nbf": payloadOptions.nbf,
            "vc": [
                "@context": [
                    "https://www.w3.org/2018/credentials/v1"
                ],
                "type": [
                    "VerifiableCredential",
                    Constants.VC.CommentVC.COMMENT_VC_TYPE_VALUE,
                ],
                "credentialSubject": [
                    "url": comment.url,
                    "comment": comment.comment,
                    "bool_value": comment.boolValue.rawValue,
                ],
            ],
        ]

        let result = JWTUtil.sign(keyAlias: keyAlias, header: header, payload: payload)
        switch result {
            case let .success(jwt):
                return jwt
            case let .failure(error):
                fatalError("Failed to sign JWT: \(error)")
        }
    }

    func getJwk() -> [String: String] {
        if !KeyPairUtil.isKeyPairExist(alias: self.keyAlias) {
            do {

                try KeyPairUtil.generateSignVerifyKeyPair(alias: self.keyAlias)
            }
            catch {
                fatalError("Failed to generate key pair: \(error)")
            }
        }
        guard let publicKey = KeyPairUtil.getPublicKey(alias: self.keyAlias) else {
            fatalError("Public key not found for alias: \(keyAlias)")
        }
        return KeyPairUtil.publicKeyToJwk(publicKey: publicKey)!
    }

}
