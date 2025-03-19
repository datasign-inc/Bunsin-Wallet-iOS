//
//  SubmitCredentialsPreviewModel.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/10/31.
//

class SubmitCredentialsPreviewModel: SubmitCredentialsViewModel {

    override func submitCredentials(signingRequestViewModel: SigningRequestViewModel) async {
        print("submit button tapped!")

        /*
        return TokenSendResult(
            statusCode: 200, location: "https://redirect.preview.example.com/", cookies: nil,
            sharedIdToken: nil, sharedCredentials: nil)
         */
    }

    // todo: プレビューとして適切な実装に変更する
    override func prepareForAffiliationCredential(
        presentationDefinition: PresentationDefinition
    ) {

        if model.affiliationCredentials.count > 0 {
            // todo: 将来的に複数の所属証明書を提示する場合があり得るので、先頭のみを取得する処理は修正すべき
            let firstCredential = model.affiliationCredentials.first!
            switch firstCredential.format {
                case "vc+sd-jwt":
                    if let matched = presentationDefinition.matchSdJwtVcToRequirement(
                        sdJwt: firstCredential.payload)
                    {
                        let (inputDescriptors, disclosuresWithOptionality) = matched
                        self.model.affiliationCredInputDescriptor = inputDescriptors

                        self.model.affiliationCredRequiredClaims = disclosuresWithOptionality.filter
                        { d in
                            d.isSubmit && !d.isUserSelectable
                        }
                        self.model.affiliationCredUserSelectableClaims =
                            disclosuresWithOptionality.filter { d in
                                d.isUserSelectable
                            }
                        self.model.affiliationCredUndisclosedClaims =
                            disclosuresWithOptionality.filter { d in
                                !d.isSubmit && !d.isUserSelectable
                            }
                    }
                    else {
                        print("credential does not match to presentation definition")
                    }
                default:
                    model.showAlert = true
                    model.alertTitle = "unexpected credential type"
                    model.alertMessage = "affiliation credential must be vc+sd-jwt"
            }
        }
    }

    override func prepareCommentCredential(presentationDefinition: PresentationDefinition) {
        for inputDescriptor in presentationDefinition.inputDescriptors {
            if inputDescriptor.id == Constants.VC.CommentVC.COMMENT_VC_INPUT_DESCRIPTOR_ID {
                model.commentCredentialInputDescriptor = inputDescriptor
            }
        }
    }

    override func loadData(
        credentials: [Credential?],
        presentationDefinition: PresentationDefinition?,
        isCommentVcRequired: Bool
    ) async {
        isLoading = true
        print("load data..")

        model.commentCredential = nil
        model.affiliationCredentials = []
        for credential in credentials {
            guard let credential = credential else {
                continue
            }
            if credential.credentialType == Constants.VC.CommentVC.COMMENT_VC_TYPE_VALUE {
                model.commentCredential = credential
            }
            else {
                model.affiliationCredentials.append(credential)
            }
        }

        prepareCommentCredential(presentationDefinition: presentationDefinition!)

        prepareForAffiliationCredential(
            presentationDefinition: presentationDefinition!)

        isLoading = false
        hasLoadedData = true
        print("done")
    }
}
