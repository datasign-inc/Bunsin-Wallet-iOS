//
//  Base64ImageView.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/12/12.
//

import SwiftUI

struct Base64ImageView: View {
    let base64String: String

    var body: some View {
        VStack(alignment: .leading) {
            if let image = imageFromBase64String(base64String) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            }
            else {
                Image(systemName: "person.fill.xmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }

    // Base64文字列からUIImageを生成する関数
    private func imageFromBase64String(_ base64String: String) -> UIImage? {
        // プレフィックスを削除
        guard
            let data = Data(
                base64Encoded: base64String.replacingOccurrences(
                    of: "data:image/jpeg;base64,", with: ""))
        else {
            return nil
        }
        return UIImage(data: data)
    }
}
