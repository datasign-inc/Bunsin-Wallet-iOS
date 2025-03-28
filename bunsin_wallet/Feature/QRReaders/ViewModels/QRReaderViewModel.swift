//
//  ScannerViewModel.swift
//  bunsin_wallet
//
//  Created by SadamuMatsuoka on 2024/01/16.
//

import Foundation
import SwiftUI

@Observable class QRReaderViewModel {
    /// QRコードを読み取る時間間隔
    let scanInterval: Double = 1.0
    var lastQrCode: String = ""
    var isShowing: Bool = false
    var scanResultType: ScanResultType = .unknown
    var credentialOfferArgs: CredentialOfferArgs?
    var verificationArgs: VerificationArgs?
    var sharingCredentialArgs: SharingCredentialArgs?

    struct QRCodeData: Decodable {
        var format: String
        var credential: String
        var display: String
    }

    /// QRコード読み取り時に実行される。
    func onFoundQrCode(_ code: String) {
        lastQrCode = code
        if code.isOpenIdCredentialOffer {
            let args = CredentialOfferArgs()
            args.credentialOffer = lastQrCode
            credentialOfferArgs = args
            scanResultType = .openIDCredentialOffer
        }
        else if code.isSiopv2 {
            let args = SharingCredentialArgs()
            args.url = code
            sharingCredentialArgs = args
            scanResultType = .openID4VP
        }
        else if code.isOpenId4VP {
            let args = SharingCredentialArgs()
            args.url = code
            sharingCredentialArgs = args
            scanResultType = .openID4VP
        }
        else if let decompressedString = ZipUtil.decompressString(compressed: code),
            decodeQRCodeData(from: decompressedString) != nil
        {
            scanResultType = .compressedString
            let args = VerificationArgs()
            args.compressedString = lastQrCode
            verificationArgs = args
        }
        else {
            scanResultType = .unknown
        }
    }

    // JSON文字列からQRCodeDataオブジェクトにデコードするヘルパーメソッド
    private func decodeQRCodeData(from string: String) -> QRCodeData? {
        guard let data = string.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(QRCodeData.self, from: data)
    }
}

// スキャン結果のタイプを識別するためのenum
enum ScanResultType {
    case openIDCredentialOffer
    case compressedString
    case openID4VP
    case unknown
}
