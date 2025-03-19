//
//  CommentVcIssuerTests.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/10/15.
//

import XCTest

@testable import bunsin_wallet

class CommentVcIssuerTests: XCTestCase {

    var keyAlias = "testKeyForCommentVc"
    var publicKey: SecKey?
    var privateKey: SecKey?

    override func setUpWithError() throws {
        super.setUp()
        // キーペアの生成
        try KeyPairUtil.generateSignVerifyKeyPair(alias: keyAlias)
        (privateKey, publicKey) = KeyPairUtil.getKeyPair(alias: keyAlias)!
    }

    func testIssueCredential() {
        // テストデータの準備
        let url = "https://example.com"
        let commentText = "This is a test comment."
        let contentTruth = ContentTruth.trueContent

        // CommentVcIssuerのインスタンスを作成
        let issuer = CommentVcIssuer(keyAlias: keyAlias)

        // issueCredentialメソッドを呼び出して、生成されたCredentialを取得
        let credential = issuer.issueCredential(
            url: url, comment: commentText, contentTruth: contentTruth)

        // Credentialの検証
        XCTAssertEqual(credential.format, "jwt_vc_json", "フォーマットが期待通りではありません")
        XCTAssertEqual(
            credential.credentialType, Constants.VC.CommentVC.COMMENT_VC_TYPE_VALUE,
            "タイプが期待通りではありません")

        // JWTの検証
        let verifyResult = JWTUtil.verifyJwt(jwt: credential.payload, publicKey: publicKey!)
        switch verifyResult {
            case .success(let jwt):
                let payload = jwt.body
                guard let vc = payload["vc"] as? [String: Any],
                    let credentialSubject = vc["credentialSubject"] as? [String: Any],
                    let vcCommentText = credentialSubject["comment"] as? String,
                    let vcBoolValue = credentialSubject["bool_value"] as? Int,
                    let vcUrl = credentialSubject["url"] as? String
                else {
                    XCTFail("JWTのペイロードから必要なデータを取得できませんでした")
                    return
                }

                XCTAssertEqual(vcCommentText, commentText, "コメントが一致しません")
                XCTAssertEqual(vcUrl, url, "URLが一致しません")
                XCTAssertEqual(vcBoolValue, contentTruth.rawValue, "真偽値が一致しません")
            case .failure(let error):
                XCTFail("JWTの検証に失敗しました: \(error)")
        }

        // その他のプロパティの確認
        XCTAssertTrue(
            credential.metaData.credentialIssuer.hasPrefix("https://self-issued.boolcheck.com/"))
    }

    func testGenerateCommentVc() {
        // テストデータの準備
        let url = "https://example.com"
        let commentText = "This is a test comment."
        let comment = Comment(url: url, comment: commentText, boolValue: .trueContent)
        let headerOptions = CommentVcHeaderOptions(alg: "ES256", typ: "JWT")
        let payloadOptions = CommentVcPayloadOptions(
            iss: "https://issuer.example.com", nbf: 1_697_040_000)

        // CommentVcIssuerのインスタンスを作成
        let issuer = CommentVcIssuer(keyAlias: keyAlias)

        // テスト対象のメソッドを呼び出し
        let jwt = issuer.generateJwt(
            comment: comment, headerOptions: headerOptions, payloadOptions: payloadOptions)

        let verifyResult = JWTUtil.verifyJwt(jwt: jwt, publicKey: publicKey!)
        switch verifyResult {
            case .success(let jwt):
                let payload = jwt.body
                guard let vc = payload["vc"] as? [String: Any],
                    let credentialSubject = vc["credentialSubject"] as? [String: Any],
                    let vcCommentText = credentialSubject["comment"] as? String,
                    let vcBoolValue = credentialSubject["bool_value"] as? Int,
                    let vcUrl = credentialSubject["url"] as? String
                else {
                    XCTFail()
                    return
                }
                XCTAssertTrue(commentText == vcCommentText)
                XCTAssertTrue(vcUrl == url)
                XCTAssertTrue(vcBoolValue == ContentTruth.trueContent.rawValue)
            case .failure(let error):
                print(error)
                XCTFail()
        }
    }
}
