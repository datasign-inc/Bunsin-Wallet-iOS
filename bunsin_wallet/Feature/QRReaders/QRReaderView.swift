//
//  QRScannerView.swift
//  bunsin_wallet
//
//  Created by SadamuMatsuoka on 2024/01/16.
//

import SwiftUI

struct QRReaderView: View {
    var viewModel: QRReaderViewModel
    @Binding var nextScreen: ScreensOnFullScreen

    @State private var hasCameraAccess: Bool = false
    @State private var qrCodeScannerView = QrCodeScannerView()  // QrCodeScannerViewのインスタンス
    @State private var isRequestingPermission: Bool = false

    @Environment(\.dismiss) var dismiss
    @Environment(DataReadByQRReader.self) var dataReadByQRReader
    @Environment(SharingRequestModel.self) var sharingRequestModel

    init(
        viewModel: QRReaderViewModel = QRReaderViewModel(),
        nextScreen: Binding<ScreensOnFullScreen>
    ) {
        self.viewModel = viewModel
        self._nextScreen = nextScreen
    }

    var body: some View {
        ZStack {
            if isRequestingPermission {
                // ローディングインジケーターを表示
                ProgressView()
            }
            else if self.hasCameraAccess {
                // QRコード読み取りViewGeneric
                qrCodeScannerView
                    .found(r: self.viewModel.onFoundQrCode)
                    .interval(delay: self.viewModel.scanInterval)
            }
            else {
                Text("camera_authorization_required")
            }

            VStack {
                Spacer()
                VStack {
                    Text("scan_the_qr_code")
                        .modifier(BodyWhite())
                        .padding(.vertical, 64)

                    Button(
                        action: {
                            dismiss()
                            nextScreen = .root

                        },
                        label: {
                            Text(NSLocalizedString("cancel", comment: "Cancel button"))
                                .font(.title2)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 3)
                        }
                    )
                    .modifier(BodyWhite())
                    .controlSize(.extraLarge)
                }
                .cornerRadius(10)  // 角丸設定
                .padding()
            }
            .padding()
            .onChange(of: viewModel.scanResultType) {
                self.handleNavigation(scanResultType: viewModel.scanResultType)
            }
            .onAppear(perform: self.checkCameraPermission)
        }
        .toolbar(.hidden, for: .tabBar)
    }

    private func handleNavigation(scanResultType: ScanResultType) {
        switch scanResultType {
            case .openIDCredentialOffer:
                dataReadByQRReader.credentialOfferArgs = viewModel.credentialOfferArgs
                dismiss()
                nextScreen = ScreensOnFullScreen.credentialOffer
            case .openID4VP:
                dataReadByQRReader.sharingCredentialArgs = viewModel.sharingCredentialArgs
                dismiss()
                nextScreen = ScreensOnFullScreen.sharingRequest
            case .compressedString:
                dataReadByQRReader.verificationArgs = viewModel.verificationArgs
                dismiss()
                nextScreen = ScreensOnFullScreen.verification
            default:
                break
        }
    }

    private func checkCameraPermission() {
        print("checkCameraPermission")
        if CameraPermissionHandler.hasCameraPermission() {
            hasCameraAccess = true
        }
        else {
            isRequestingPermission = true  // パーミッション要求開始
            CameraPermissionHandler.requestCameraPermission { granted in
                DispatchQueue.main.async {
                    isRequestingPermission = false  // パーミッション要求終了
                    if granted {
                        self.hasCameraAccess = true
                        // パーミッションダイアログでカメラセッションが動かなくなるので一度セッションを停止
                        self.qrCodeScannerView.stopSession()
                    }
                }
            }
        }
    }
}

#Preview {
    QRReaderView(nextScreen: .constant(ScreensOnFullScreen.root))
}
