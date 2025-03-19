//
//  SharingRequesModel.swift
//  bunsin_wallet
//
//  Created by SadamuMatsuoka on 2024/01/10.
//

import Foundation

//
// todo: After integration into the `SigningRequestModel` side, this class should be deleted.
//

@Observable
class SharingRequestModel {
    var redirectTo: String? = nil
    var postResult: TokenSendResult? = nil
    var presentationDefinition: PresentationDefinition? = nil
    init(presentationDefinition: PresentationDefinition? = nil) {
        self.presentationDefinition = presentationDefinition
    }

    var type: String? = nil
    var data: [SubmissionCredential]? = nil
    var metadata: CredentialIssuerMetadata? = nil
    func setSelectedCredentials(
        data: [SubmissionCredential],
        metadata: CredentialIssuerMetadata
    ) {
        self.data = data
        self.metadata = metadata
    }
}
