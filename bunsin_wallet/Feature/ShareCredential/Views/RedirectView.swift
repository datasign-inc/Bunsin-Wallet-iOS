//
//  RedirectView.swift
//  bunsin_wallet
//
//  Created by 若葉良介 on 2024/02/05.
//

import SafariServices
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let urlString: String
    let cookieStrings: [String]
    var onClose: () -> Void
    var openURL: (URL, @escaping (Bool) -> Void) -> Void = { url, completion in
        UIApplication.shared.open(url, options: [:], completionHandler: completion)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        let cookies = cookieStrings.compactMap { cookieString -> HTTPCookie? in
            let parts = cookieString.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return nil }

            let properties: [HTTPCookiePropertyKey: Any] = [
                .name: parts[0],
                .value: parts[1],
                .path: "/",
                .domain: url.host ?? "",
            ]

            return HTTPCookie(properties: properties)
        }

        let dataStore = webView.configuration.websiteDataStore
        for cookie in cookies {
            dataStore.httpCookieStore.setCookie(cookie)
        }

        webView.load(URLRequest(url: url))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, onClose: onClose, openURL: openURL)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var onClose: () -> Void
        var openURL: (URL, @escaping (Bool) -> Void) -> Void

        init(
            _ parent: WebView, onClose: @escaping () -> Void,
            openURL: @escaping (URL, @escaping (Bool) -> Void) -> Void
        ) {
            self.parent = parent
            self.onClose = onClose
            self.openURL = openURL
        }

        func webView(
            _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if let url = navigationAction.request.url {
                if url.scheme == "openid-credential-offer" {
                    handleCustomSchemeInWKWebView(url: url)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }

        func handleCustomSchemeInWKWebView(url: URL) {
            print("Handling custom scheme URL: \(url)")
            openURL(url) { success in
                if success {
                    DispatchQueue.main.async {
                        self.onClose()
                    }
                }
                else {
                    print("Failed to open URL: \(url)")
                }
            }
        }
    }
}

struct RedirectView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var urlString: String
    // var cookies: [HTTPCookie] = []
    var cookieStrings: [String] = []

    var body: some View {
        WebView(
            urlString: urlString, cookieStrings: cookieStrings,
            onClose: {
                self.presentationMode.wrappedValue.dismiss()
            },
            openURL: { url, completion in
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: completion)
                }
                else {
                    print("Cannot open URL: \(url)")
                    completion(false)
                }
            }
        )
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

#Preview {
    RedirectView(urlString: "https://example.com")
}
