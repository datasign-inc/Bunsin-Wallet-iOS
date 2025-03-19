//
//  AccordionWhite.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/10/29.
//

import SwiftUI

struct AccordionWhite: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(LocalizedStringKey(title))
                    .font(.title2)
            }
            .padding(20)
            .frame(maxWidth: .infinity)  // 最小高さを設定
            .frame(height: 46)
            .foregroundColor(Color("outlinedButtonTextColor"))
            .background(Color("outlinedButtonBackgroundColor"))  // ボタンの背景色
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color("outlinedButtonBorderColor"), lineWidth: 1)  // 黒い枠線
            )
        }
    }
}

#Preview {
    AccordionWhite(
        title: "select_a_certificate",
        action: {
            print("Button tapped")
        })
}
