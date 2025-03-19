//
//  VcJwtJsonClaim.swift
//  bunsin_wallet
//
//  Created by SadamuMatsuoka on 2024/01/14.
//

import Foundation
import SwiftUI

struct JwtVcJsonClaim: Codable {
    var claims: [String: String]
}
