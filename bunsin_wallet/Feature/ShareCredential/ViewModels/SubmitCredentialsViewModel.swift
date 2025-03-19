//
//  SubmitCredentialsViewModel.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/10/30.
//

import Foundation
import SwiftUI

func jwtVcJsonClaimsTobeDisclosed(jwt: String) -> [Disclosure] {
    if let (_, body, _) = try? JWTUtil.decodeJwt(jwt: jwt),
        let vc = body["vc"] as? [String: Any],
        let credentialSubject = vc["credentialSubject"] as? [String: Any]
    {
        let disclosures = credentialSubject.map { key, value in
            // valueがネストしていることは想定していない。
            return Disclosure(disclosure: nil, key: key, value: value as? String)
        }
        return disclosures
    }
    return []
}

@Observable
class SubmitCredentialsViewModel {
    var model = SubmitCredentialsModel()
    var isLoading = false
    var hasLoadedData = false

    @ObservationIgnored
    private let credentialDataManager = CredentialDataManager(container: nil)

    func submitCredentials(signingRequestViewModel: SigningRequestViewModel) async {
        var credentials: [SubmissionCredential] = []
        var commentCredentialToBeSent: Credential? = nil

        if signingRequestViewModel.isCommentVcRequired() {
            guard let commentCredentialInputDescriptor = model.commentCredentialInputDescriptor,
                let commentCredential = model.commentCredential
            else {
                model.showAlert = true
                model.alertTitle = "unable to send credential"
                model.alertMessage = "The comment credential to be sent are not loaded."
                return
            }

            let submissionCommentCredential = commentCredential.createSubmissionCredential(
                inputDescriptor: commentCredentialInputDescriptor,
                discloseClaims:
                    jwtVcJsonClaimsTobeDisclosed(jwt: commentCredential.payload).map { it in
                        return DisclosureWithOptionality(
                            disclosure: it, isSubmit: true, isUserSelectable: false)
                    }
            )

            commentCredentialToBeSent = commentCredential
            credentials.append(submissionCommentCredential)
        }

        if let affiliationCredential = model.affiliationCredentials.first,
            let affiliationCredentialInputDescriptor = model.affiliationCredInputDescriptor
        {
            let affiliationDisclosedClaims =
                (model.affiliationCredRequiredClaims + model.affiliationCredUserSelectableClaims)
                .filter { it in it.isSubmit }

            let submissionAffiliationCredential = affiliationCredential.createSubmissionCredential(
                inputDescriptor: affiliationCredentialInputDescriptor,
                discloseClaims: affiliationDisclosedClaims
            )

            credentials.append(submissionAffiliationCredential)
        }
        let result = await signingRequestViewModel.shareToken(credentials: credentials)

        switch result {
            case .success(let postResult):
                print("Token sharing succeeded : \(postResult)")
                model.showAlert = true
                model.alertTitle = String(localized: "Successful")
                model.alertMessage = String(localized: "Transmission succeeded")
                do {
                    if let comment = commentCredentialToBeSent {
                        try credentialDataManager.saveCredentialData(
                            credentialData: comment.toDatastoreFormat())
                    }
                }
                catch {
                    print("unable to save comment credential")
                }

                if let location = postResult.location {
                    model.locationAfterVp = location
                }
            case .failure(let error):
                print(
                    "Token sharing failed with error: \(error)"
                )
                model.showAlert = true
                model.alertTitle = "Failed to send token"
                model.alertMessage = "Token sharing failed with error: \(error)"
        }
    }

    func prepareCommentCredential(presentationDefinition: PresentationDefinition) {
        for inputDescriptor in presentationDefinition.inputDescriptors {
            if inputDescriptor.id == Constants.VC.CommentVC.COMMENT_VC_INPUT_DESCRIPTOR_ID {
                model.commentCredentialInputDescriptor = inputDescriptor
            }
        }
    }

    func prepareForAffiliationCredential(
        presentationDefinition: PresentationDefinition
    ) {
        if model.affiliationCredentials.count > 0 {
            // todo: 将来的に複数の所属証明書を提示する場合があり得るので、先頭のみを取得する処理は修正すべき
            let firstCredential = model.affiliationCredentials.first!

            let metaData = firstCredential.metaData
            let credentialConfigurationsSupported = metaData.credentialConfigurationsSupported[
                firstCredential.credentialType]
            switch firstCredential.format {
                case "vc+sd-jwt":
                    if let matched = presentationDefinition.matchSdJwtVcToRequirement(
                        sdJwt: firstCredential.payload)
                    {
                        let (inputDescriptors, disclosuresWithOptionality) = matched
                        let localized = disclosuresWithOptionality.localize(
                            locale: "ja-JP",
                            credentialConfiguration: credentialConfigurationsSupported)
                        self.model.affiliationCredInputDescriptor = inputDescriptors
                        // todo: メタデータのorderに則ってソートすべき
                        self.model.affiliationCredRequiredClaims = localized.filter { d in
                            d.isSubmit && !d.isUserSelectable
                        }
                        // todo: メタデータのorderに則ってソートすべき
                        self.model.affiliationCredUserSelectableClaims =
                            localized.filter { d in
                                d.isUserSelectable
                            }
                        self.model.affiliationCredUndisclosedClaims =
                            localized.filter { d in
                                !d.isSubmit && !d.isUserSelectable
                            }
                    }
                case "jwt_vc_json":
                    if let matched = presentationDefinition.matchJwtVcJsonToRequirement(
                        jwtVcJson: firstCredential.payload)
                    {
                        let (inputDescriptor, disclosuresWithOptionality) = matched
                        let localized = disclosuresWithOptionality.localize(
                            locale: "ja-JP",
                            credentialConfiguration: credentialConfigurationsSupported)
                        self.model.affiliationCredInputDescriptor = inputDescriptor
                        self.model.affiliationCredRequiredClaims = localized.filter { d in
                            d.isSubmit && !d.isUserSelectable
                        }
                        self.model.affiliationCredUserSelectableClaims = []
                        self.model.affiliationCredUndisclosedClaims = []

                    }
                default:
                    model.showAlert = true
                    model.alertTitle = "unexpected credential type"
                    model.alertMessage =
                        "credential type \(firstCredential.format) is not supported"
            }
        }
    }

    func loadData(
        credentials: [Credential?],
        presentationDefinition: PresentationDefinition?,
        isCommentVcRequired: Bool
    ) async {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            print("now previewing")
            return
        }
        guard !hasLoadedData else { return }
        isLoading = true
        print("load data..")

        // setting credentials
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

        if isCommentVcRequired {
            if model.commentCredential == nil {
                model.showAlert = true
                model.alertTitle = "Comment is not found"
                model.alertMessage = "Comment credential must be required"
                return
            }
            
            // check presentation definition
            guard let presentationDefinition = presentationDefinition else {
                model.showAlert = true
                model.alertTitle = "invalid presentation definition"
                model.alertMessage = "invalid presentation definition"
                return
            }

            // setup inputDescriptor for commentCredential
            prepareCommentCredential(presentationDefinition: presentationDefinition)
            if model.commentCredentialInputDescriptor == nil {
                model.showAlert = true
                model.alertTitle = "invalid presentation definition"
                model.alertMessage = "input descriptor for comment is not found"
                return
            }
        }

        if let pred = presentationDefinition {
            prepareForAffiliationCredential(
                presentationDefinition: pred)
        }

        isLoading = false
        hasLoadedData = true
        print("done")
    }
}
