//
//  CommentTypes.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/10/15.
//

struct CommentVcHeaderOptions: Codable {
    var alg: String = "ES256"
    var typ: String = "JWT"
}

struct CommentVcPayloadOptions: Codable {
    // See below for value definitions.
    // https://www.notion.so/bool-check-app-0b1a6e0618134dacbdeae7d35e6f01cf?pvs=4#9937362bbf2445079805e5cec9335455
    let iss: String
    let nbf: Int64
}

enum ContentTruth: Int, Codable {
    // See below for value definitions.
    // https://www.notion.so/bool-check-app-0b1a6e0618134dacbdeae7d35e6f01cf?pvs=4#97ffcd4a031c43e881199d8f4529c35e
    case trueContent = 1
    case falseContent = 0
    case indeterminateContent = 2
}

struct Comment: Codable {
    // See below for definition
    // https://www.notion.so/bool-check-app-0b1a6e0618134dacbdeae7d35e6f01cf?pvs=4#9937362bbf2445079805e5cec9335455
    let url: String
    let comment: String
    let boolValue: ContentTruth
}
