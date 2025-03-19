//
//  SigningRequestModel.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/10/24.
//

import Foundation

struct SigningRequestModel {
    var vpUrl: String?
    var signingUrl: String?
    var signingBoolValue: Int?
    var signingComment: String?
    var clientInfo: ClientInfo?

    // see https://docs.google.com/presentation/d/1f_F4s0xyXGTJ-MvOVyDpEGFhic-Zx0KzX-xshfRUlCk/edit?usp=sharing
    var onetimeKeyAliasForAnonymousComment: String? = nil

    var authenticatedBeforeKeyAccess = false
    var showAlert = false
    var alertTitle = ""
    var alertMessage = ""

    func boolValueAsString() -> String {
        guard let value = self.signingBoolValue else {
            return NSLocalizedString("Unknown", comment: "")
        }
        switch value {
            case 0:
                return NSLocalizedString("False", comment: "")
            case 1:
                return NSLocalizedString("True", comment: "")
            case 2:
                return NSLocalizedString("Else", comment: "")
            default:
                return NSLocalizedString("Unknown", comment: "")
        }
    }
}
