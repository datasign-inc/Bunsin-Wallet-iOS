//
//  CredentialListViewModel.swift
//  bunsin_wallet
//
//  Created by 若葉良介 on 2023/12/22.
//

import Foundation

@Observable
class CredentialListViewModel {

    var dataModel: CredentialListModel = .init()
    @ObservationIgnored
    private let credentialDataManager = CredentialDataManager(container: nil)

    func loadData(presentationDefinition: PresentationDefinition? = nil) {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            print("now previewing")
            return
        }
        guard !dataModel.hasLoadedData else { return }
        dataModel.isLoading = true
        print("load data..")

        var credentialList: [Credential] = []
        for rawCredential in credentialDataManager.getAllCredentials() {
            let converted = rawCredential.toCredential()
            if converted != nil
                && converted?.credentialType != Constants.VC.CommentVC.COMMENT_VC_TYPE_VALUE
            {
                credentialList.append(converted!)
            }
            else {
                print("Malformed Credential Found")
            }
        }

        if let pd = presentationDefinition {
            dataModel.credentials = credentialList.filter {
                pd.isSatisfy(credential: $0)
            }
        }
        else {
            dataModel.credentials = credentialList
        }

        dataModel.isLoading = false
        dataModel.hasLoadedData = !dataModel.credentials.isEmpty
        print("done")
    }

    func deleteCredential(credential: Credential) {
        print("delete: \(credential.id), \(credential.format)")
        credentialDataManager.deleteCredentialById(id: credential.id)
        dataModel.hasLoadedData = false
        loadData()
    }

    func reload() {
        dataModel.hasLoadedData = false
        loadData()
    }
}
