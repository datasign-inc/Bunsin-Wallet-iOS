import LocalAuthentication
//
//  AuthenticationView.swift
//  bunsin_wallet
//
//  Created by 若葉良介 on 2024/01/08.
//
import SwiftUI

struct AuthenticationView: View {
    // @State private var isUnlocked = false
    private var authenticationManager: AuthenticationManager
    private var canEvaluatePolicy: Bool

    init(authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
        self.canEvaluatePolicy = authenticationManager.canEvaluateDeviceOwnerAuthenticationPolicy()
    }

    private var lockedView: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                Image("splash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width * 0.75)  // 画面幅の50%を画像幅に設定
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)  // 画像を中央揃え

                Text("Locked for security")
                    .font(.headline)

                Button(action: {
                    self.authenticationManager.authenticate()
                }) {
                    Text("authentication")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .background(colorFromHex("#00A739"))
                        .cornerRadius(24)
                }

            }.frame(height: geometry.size.height * 0.6)
        }

    }

    var body: some View {
        VStack {
            if self.authenticationManager.isUnlocked {
                // 認証成功後に表示されるビュー
                Text("authentication_succeeded")
            }
            else {
                // 認証画面
                if canEvaluatePolicy {
                    lockedView
                }
                else {
                    Text("recommend_biometric_authentication")
                        .padding(16)
                    Button("without_biometric_authentication") {
                        self.authenticationManager.authenticate()
                    }

                }
            }
        }
    }
}

#Preview {
    AuthenticationView(authenticationManager: AuthenticationManager())
}
