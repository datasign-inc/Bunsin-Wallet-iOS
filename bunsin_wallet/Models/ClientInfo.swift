//
//  ClientInfo.swift
//  bunsin_wallet
//
//  Created by SadamuMatsuoka on 2024/01/10.
//

import Foundation
import SwiftUI

struct ClientInfo: Codable, Equatable {
    var clientId: String
    var name: String
    var logoUrl: String?
    var policyUrl: String
    var tosUrl: String
    var certificateInfo: CertificateInfo?
    var verified: Bool = true

    var logoImage: AnyView? {
        let fallBackLogoImage =
            isClientBoolcheck(clientId: self.clientId)
            ? AnyView(Image("logo_boolcheck").resizable()) : ImageLoader.questionMark
        if let url = logoUrl {
            return ImageLoader.loadImage(
                from: url,
                fallBack: fallBackLogoImage)
        }
        return fallBackLogoImage
    }

    static func == (lhs: ClientInfo, rhs: ClientInfo) -> Bool {
        return lhs.name == rhs.name
    }
}
