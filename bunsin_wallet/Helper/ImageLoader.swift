//
//  ImageLoader.swift
//  bunsin_wallet
//
//  Created by SadamuMatsuoka on 2023/12/30.
//

import SwiftUI

enum ImageLoader {

    static let questionMark =
        AnyView(
            Image(systemName: "questionmark.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.gray)
                .frame(maxWidth: 100, maxHeight: 100)
        )

    static let credentialCard = AnyView(
        Image(systemName: "person.text.rectangle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.gray)
            .frame(maxWidth: 100, maxHeight: 100)
    )

    static func loadImage(from urlString: String?, fallBack: AnyView = AnyView(EmptyView()))
        -> AnyView
    {
        if let urlString = urlString, let url = URL(string: urlString) {
            return AnyView(
                AsyncImage(url: url) { phase in
                    switch phase {
                        case .success(let image):
                            image.resizable()
                        case .empty, .failure:
                            fallBack
                        @unknown default:
                            fallBack
                    }
                })
        }
        else {
            return fallBack
        }
    }
}
