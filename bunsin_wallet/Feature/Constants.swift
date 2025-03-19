//
//  Constants.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/01/15.
//

import Foundation

struct Constants {
    struct Wallet {
        static let PRIVACY_POLICY_URL = "https://bunsin.io/wallet/privacy/index.html"
        static let TOS_URL = "https://bunsin.io/wallet/tos/index.html"
    }
    struct VC {
        struct CommentVC {
            static let RELYING_PARTY_DOMAIN = "boolcheck.com"

            static let COMMENT_VC_INPUT_DESCRIPTOR_ID = "true_false_comment"
            static let COMMENT_VC_TYPE_VALUE = "CommentCredential"
            static let TEXT_PATH = "$.vc.credentialSubject.comment"
            static let URL_PATH = "$.vc.credentialSubject.url"
            static let BOOL_VALUE_PATH = "$.vc.credentialSubject.bool_value"
        }
    }
    // boolcheck.comへの投稿に関する鍵の使い方については、以下の4スライド目も参照
    // https://docs.google.com/presentation/d/1f_F4s0xyXGTJ-MvOVyDpEGFhic-Zx0KzX-xshfRUlCk/edit?usp=sharing
    struct Cryptography {
        static let KEY_BINDING = "bindingKey"
        static let KEY_PAIR_ALIAS_FOR_KEY_JWT_VP_JSON = "jwtVpJsonKey"
    }
}

func isClientBoolcheck(clientId: String) -> Bool {
    if let url = URL(string: clientId),
        let host = url.host
    {
        return host.hasSuffix(Constants.VC.CommentVC.RELYING_PARTY_DOMAIN)
    }
    return false
}
