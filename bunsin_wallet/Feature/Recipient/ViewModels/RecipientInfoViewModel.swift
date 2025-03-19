//
//  RecipientInfoViewModel.swift
//  bunsin_wallet
//
//  Created by SadamuMatsuoka on 2024/02/02.
//

import Foundation

@Observable class RecipientInfoViewModel {
    var certificateInfo: CertificateInfo?
    var hasLoadedData = false
    var isLoading = false

    func loadCertificateInfo(for url: String) {
        guard !self.hasLoadedData else { return }
        self.isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            if url != "" {
                let (certificateInfo, _) = extractFirstCertSubject(url: url)
                DispatchQueue.main.async {
                    self.certificateInfo = certificateInfo
                }
            }
        }
        self.isLoading = false
        self.hasLoadedData = true
    }
}
