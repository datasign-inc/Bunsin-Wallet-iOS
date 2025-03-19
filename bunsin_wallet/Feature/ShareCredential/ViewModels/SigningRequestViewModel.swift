//
//  SigningRequestViewModel.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/10/24.
//

import Foundation

enum SigningRequestError: Error {
    case presentationDefinitionIsUndefined
    case vpUriIsUndefined
    case clientIdNotFound
    case clientIdIsMalformed
    case seedForIdTokenIsUndefined
    case unableToGetSiopAccount
    case authorizationRequestError(AuthorizationRequestError)
    case unableToSetupPairwiseAccount
    case signingTargetNotFound
    case illegalKeyRingState
    case illegalSeedState
    case illegalAccountState
}

func generateRandomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    return String((0..<length).compactMap { _ in letters.randomElement() })
}

@Observable
class SigningRequestViewModel {

    var model: SigningRequestModel = SigningRequestModel()
    var isLoading = false
    var hasLoadedData = false

    @ObservationIgnored
    var openIdProvider: OpenIdProvider? = nil
    @ObservationIgnored
    var presentationDefinition: PresentationDefinition? = nil
    @ObservationIgnored
    var seed: String?
    @ObservationIgnored
    var defaultAnonAccount: Account?
    @ObservationIgnored
    var defaultIdentAccount: Account?

    private func accessPairwiseAccountManager() async throws {
        do {
            let dataStore = PreferencesDataStore.shared
            let seed = try await dataStore.getSeed()
            if seed != nil && !seed!.isEmpty {
                print("Accessed seed successfully")
                self.seed = seed
            }
            else {
                // 初回のシード生成
                guard let hdKeyRing = HDKeyRing() else {
                    throw SigningRequestError.illegalKeyRingState
                }
                guard let newSeed = hdKeyRing.getMnemonicString() else {
                    throw SigningRequestError.illegalSeedState
                }
                try dataStore.saveSeed(newSeed)
                self.seed = newSeed
            }
        }
        catch {
            // 生体認証のエラー処理
            print("Biometric Error: \(error)")
            model.alertTitle = String(localized: "Authentication Failed")
            model.alertMessage = String(localized: "Unable to authenticate. Please try again.")
            model.showAlert = true
            throw SigningRequestError.unableToSetupPairwiseAccount
        }
    }

    internal func setSigningContent() throws {
        guard let presentationDefinition = presentationDefinition else {
            model.showAlert = true
            model.alertTitle = String(localized: "error")
            model.alertMessage = String(
                localized:
                    "unable_to_get_presentation_definition")
            throw SigningRequestError.presentationDefinitionIsUndefined
        }
        let inputDescriptors = presentationDefinition.inputDescriptors
        for inputDescriptor in inputDescriptors {
            if inputDescriptor.id == Constants.VC.CommentVC.COMMENT_VC_INPUT_DESCRIPTOR_ID {
                let constraints = inputDescriptor.constraints
                if let fields = constraints.fields {
                    // todo: fieldsのどれか1つは、値に Constants.VC.CommentVC.COMMENT_VC_TYPE_VALUE を含む。
                    // そうでない場合は、ここでcontinueしてつぎの inputDescriptorにs進むべき
                    for field in fields {
                        guard let filter = field.filter else {
                            continue
                        }
                        if field.path.contains(Constants.VC.CommentVC.TEXT_PATH) {
                            model.signingComment = filter.const
                        }
                        else if field.path.contains(Constants.VC.CommentVC.BOOL_VALUE_PATH) {
                            model.signingBoolValue = filter.maximum
                        }
                        else if field.path.contains(Constants.VC.CommentVC.URL_PATH) {
                            model.signingUrl = filter.const
                        }
                    }
                }
            }
        }

        if [model.signingUrl, model.signingComment]
            .contains(where: { $0 == nil }) || model.signingBoolValue == nil
        {
            model.showAlert = true
            model.alertTitle = String(localized: "error")
            model.alertMessage = String(localized: "unable to get signing target")

            throw SigningRequestError.signingTargetNotFound
        }
    }

    func issueCommentCredential(isAnonymous: Bool) -> Credential {
        if let signingUrl = model.signingUrl, let signingComment = model.signingComment,
            let boolValueInt = model.signingBoolValue,
            let contentTruth = ContentTruth(rawValue: boolValueInt),
            let anonymousCommentKey = model.onetimeKeyAliasForAnonymousComment
        {
            let keyAlias =
                isAnonymous
                ? anonymousCommentKey : Constants.Cryptography.KEY_BINDING
            let issuer = CommentVcIssuer(keyAlias: keyAlias)
            return issuer.issueCredential(
                url: signingUrl, comment: signingComment, contentTruth: contentTruth)
        }
        else {
            // todo: error handling
            fatalError("Unable to obtain data for signature")
        }

    }

    func loadData(vpUrl: String?) async throws {

        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            print("now previewing")
            return
        }
        guard !hasLoadedData else { return }
        isLoading = true

        if !model.authenticatedBeforeKeyAccess {
            try await self.accessPairwiseAccountManager()
        }
        model.authenticatedBeforeKeyAccess = true

        guard let url = vpUrl else {
            model.showAlert = true
            model.alertTitle = String(localized: "error")
            model.alertMessage = String(localized: "invalid vp url")
            throw SigningRequestError.vpUriIsUndefined
        }
        
        model.vpUrl = url

        openIdProvider = OpenIdProvider(ProviderOption())
        print("process SIOP Request")
        let result = await openIdProvider?.processAuthRequest(url)
        switch result {
            case .success(let processedRequestData):
                // gen client info
                let clientMetadata = processedRequestData.clientMetadata
                guard let clientId = clientMetadata.clientId ?? openIdProvider?.clientId else {
                    print(clientMetadata)
                    model.showAlert = true
                    model.alertTitle = String(localized: "error")
                    model.alertMessage = String(localized: "clientId is not found")
                    throw SigningRequestError.clientIdNotFound
                }
                guard let url = URL(string: clientId), let schema = url.scheme,
                    let host = url.host
                else {
                    model.showAlert = true
                    model.alertTitle = String(localized: "error")
                    model.alertMessage = String(localized: "clientId is malformed")
                    throw SigningRequestError.clientIdIsMalformed
                }
                let clientUrl = "\(schema)://\(host)"
                print("clientId: \(clientId)")
                print("client url: \(clientUrl)")

                let (cert, derCertificates) = extractFirstCertSubject(url: clientUrl)
                // verify ov of rp
                print("verify cert chain")
                let b = try? SignatureUtil.validateCertificateChain(
                    derCertificates: derCertificates)
                print("verified: \(b ?? false)")

                guard let seed = self.seed else {
                    model.showAlert = true
                    model.alertTitle = String(localized: "error")
                    model.alertMessage = String(
                        localized: "The setup of seed has not been completed.")
                    throw SigningRequestError.seedForIdTokenIsUndefined
                }
                print("get default account")
                do {
                    let (anonAccount, identAccount) = try getDefaultAccount(
                        seed: seed, rp: clientId)
                    print("default anonymous account index: \(anonAccount.index)")
                    print("default identified account index: \(identAccount.index)")
                    defaultAnonAccount = anonAccount
                    defaultIdentAccount = identAccount
                }
                catch {
                    model.showAlert = true
                    model.alertTitle = String(localized: "error")
                    model.alertMessage = String(localized: "unable to get account")
                    throw SigningRequestError.unableToGetSiopAccount
                }

                print("set client info")
                model.clientInfo = ClientInfo(
                    clientId: clientId,
                    name: clientMetadata.clientName ?? "",
                    logoUrl: clientMetadata.logoUri ?? "",
                    policyUrl: clientMetadata.policyUri ?? "",
                    tosUrl: clientMetadata.tosUri ?? "",
                    certificateInfo: cert,
                    verified: b ?? false
                )

                print("set presentation request")
                // set presentation def
                presentationDefinition = processedRequestData.presentationDefinition
                print("success")
            case .failure(let error):
                switch error {
                    case .authRequestInputError(let subError):
                        print(subError)
                        model.alertTitle = String(
                            localized:
                                "Found wrong input. It needs to confirm client system.")
                        model.alertMessage = subError.localizedDescription
                    case .authRequestClientError(let subError):
                        print(subError)
                        switch subError {
                            case .badRequest(let reason):
                                model.alertTitle =
                                    String(
                                        localized:
                                            "Sent Wrong request. It needs to confirm the request sent."
                                    )
                                model.alertMessage = reason
                            case .compliantError(let reason):
                                model.alertTitle =
                                    String(
                                        localized:
                                            "Client error occurred. It needs to confirm wallet app."
                                    )
                                model.alertMessage = reason
                        }
                    case .authRequestServerError(let subError):
                        print(subError)
                        model.alertTitle = String(
                            localized:
                                "Unable to process request. Please try again.")
                        model.alertMessage = subError.localizedDescription
                    case .unknown(let subError):
                        model.alertTitle = String(
                            localized:
                                "Unable to process request.")
                        if let subError = subError {
                            print(subError)
                            model.alertMessage = subError.localizedDescription
                        }
                }
                model.showAlert = true
                throw SigningRequestError.authorizationRequestError(error)
            case .none:
                print("none")
        }

        if isCommentVcRequired() {
            model.onetimeKeyAliasForAnonymousComment = generateRandomString(length: 10)
            try setSigningContent()
        }

        isLoading = false
        hasLoadedData = true
    }

    private func getDefaultAccount(seed: String, rp: String) throws -> (Account, Account) {

        print("Initializing Account Manager")
        guard let accountManager = PairwiseAccount(mnemonicWords: seed) else {
            throw SigningRequestError.illegalAccountState
        }

        print("Starts the process of retrieving past account usage history")
        let idTokenSharingHistories = getStoredAccounts()
        print("histories count: \(idTokenSharingHistories.count)")
        let accounts = idTokenSharingHistories.compactMap { history in
            if let accUseCase = AccountUseCase(rawValue: history.accountUseCase) {
                return accountManager.indexToAccount(
                    index: Int(history.accountIndex), rp: history.rp, accountUseCase: accUseCase)
            }
            else {
                print("Unknown accountUsecase: \(history.accountUseCase)")
                print("Raw history value: \(history)")
                return nil
            }
        }
        print("Set the histories")
        accountManager.accounts = accounts

        print("Retrieving default anonymous account for RP: \(rp)")
        // see https://docs.google.com/presentation/d/1f_F4s0xyXGTJ-MvOVyDpEGFhic-Zx0KzX-xshfRUlCk/edit?usp=sharing
        // 匿名の場合は常に新しいIDトークンを送信する
        let anonymousAccount: Account = accountManager.nextAccount(
            rp: rp, accountUseCase: .defaultAnonymousAccount)
        accountManager.accounts.append(anonymousAccount)

        print("Retrieving default identified account for RP: \(rp)")
        var identifiedAccount: Account? = nil
        let candidatesForIdent = accountManager.getAccounts(
            rp: rp, accountUseCase: .defaultIdentifiedAccount)
        if candidatesForIdent.isEmpty {
            identifiedAccount = accountManager.nextAccount(
                rp: rp, accountUseCase: .defaultIdentifiedAccount)
        }
        else if candidatesForIdent.count == 1 {
            identifiedAccount = candidatesForIdent.first
        }
        else {
            print("Unexpected situation: multiple default identified account found for rp \(rp)")
            for elm in candidatesForIdent {
                print(
                    "account: (index, rp, usecase, thumbprint) = (\(elm.index), \(elm.rp), \(elm.accountUseCase), \(elm.thumbprint))"
                )
            }
            identifiedAccount = candidatesForIdent.first
        }

        guard let ensuredIdentified = identifiedAccount
        else {
            print(
                "Both default anonymous account and default identified account for RP(\(rp)) must be available"
            )
            throw SigningRequestError.illegalAccountState
        }

        return (anonymousAccount, ensuredIdentified)
    }

    private func getStoredAccounts() -> [Datastore_IdTokenSharingHistory] {
        print("getStoredAccounts")
        let storeManager = IdTokenSharingHistoryManager(container: nil)
        let idTokenSharingHistories = storeManager.getAll()
        return idTokenSharingHistories
    }

    func isCommentVcRequired() -> Bool {
        if let clientInfo = model.clientInfo, let vpUrl = model.vpUrl {
            return isClientBoolcheck(clientId: clientInfo.clientId) && vpUrl.isOpenId4VP
        }
        return false
    }

    func shareToken(credentials: [SubmissionCredential]?) async -> Result<TokenSendResult, Error> {
        print("Start checking the required parameters for `shareToken` process")
        guard let openIdProvider = openIdProvider,
            let anonAccount = defaultAnonAccount,
            let identAccount = defaultIdentAccount,
            let seed = seed,
            let accountManager = PairwiseAccount(mnemonicWords: seed),
            let clientId = model.clientInfo?.clientId
        else {
            let errorState =
                openIdProvider == nil
                ? ShareIdTokenError.illegalOpenIdProviderState
                : (defaultAnonAccount == nil) || (defaultIdentAccount == nil)
                    ? ShareIdTokenError.illegalAccountState
                    : seed == nil
                        ? ShareIdTokenError.illegalSeedState
                        : model.clientInfo?.clientId == nil
                            ? ShareIdTokenError.illegalOpenIdProviderState
                            : ShareIdTokenError.accountManagerError
            print("\(errorState): Initialization Failed")
            return .failure(errorState)
        }

        print("Start setup Account for ID token")
        var account: Account = identAccount
        if isClientBoolcheck(clientId: clientId) {
            if let creds = credentials {
                if creds.isEmpty {
                    // コメントを削除する場合
                    // どちらのaccountを使用すべきか、確定できない。
                    // 実名コメントを削除できないリスクを考えて、デフォルト値をidentAccountにしている
                }
                else if creds.count == 1 {
                    account = anonAccount
                }
                else {
                    // noop
                }
            }
        }

        let publicKey = accountManager.getPublicKey(index: account.index)
        let privateKey = accountManager.getPrivateKey(index: account.index)
        let keyPair = KeyPairData(publicKey: publicKey, privateKey: privateKey)
        openIdProvider.setSecp256k1KeyPair(keyPair: keyPair)

        print("Start initialization process to send vp_token")
        let keyBinding = KeyBindingImpl(keyAlias: Constants.Cryptography.KEY_BINDING)
        openIdProvider.setKeyBinding(keyBinding: keyBinding)

        var keyForJwtVpJson = Constants.Cryptography.KEY_PAIR_ALIAS_FOR_KEY_JWT_VP_JSON
        if isClientBoolcheck(clientId: clientId) {
            if let creds = credentials {
                if creds.isEmpty {
                    // コメントを削除する場合。クレデンシャルの送信は行わない。IDトークンのみを送信。
                    // jwtVpJsonは使用されないので、特に設定する必要はない。
                }
                else if creds.count == 1 {
                    guard let anonymousCommentKey = model.onetimeKeyAliasForAnonymousComment else {
                        // todo: Use an appropriate exception class.
                        print("A key to sign anonymous comments has not been set up")
                        return .failure(ShareIdTokenError.keyPairError)
                    }
                    keyForJwtVpJson = anonymousCommentKey
                }
                else {
                    keyForJwtVpJson = Constants.Cryptography.KEY_BINDING
                }
            }
        }
        let jwtVpJsonGenerator = JwtVpJsonGeneratorImpl(
            keyAlias: keyForJwtVpJson)
        openIdProvider.setJwtVpJsonGenerator(jwtVpJsonGenerator: jwtVpJsonGenerator)

        print("Start initialization process for accessing network")
        let delegate = NoRedirectDelegate()
        let configuration = URLSessionConfiguration.default
        let session = URLSession(
            configuration: configuration, delegate: delegate, delegateQueue: nil)

        print("Responding to verifier")
        let result = await openIdProvider.respondToken(credentials: credentials, using: session)
        switch result {
            case .success(let postResult):
                print("Saving hitories")
                if let sharedCredentials = postResult.sharedCredentials {
                    print("Saving vp token history")
                    let storeManager = CredentialSharingHistoryManager(container: nil)
                    for content in sharedCredentials {
                        var history = Datastore_CredentialSharingHistory()
                        history.accountIndex = Int32(account.index)
                        history.createdAt = Date().toGoogleTimestamp()
                        history.credentialID = content.id
                        for (_, claim) in content.sharedClaims.enumerated() {
                            var claimInfo = Datastore_ClaimInfo()
                            claimInfo.claimKey = claim.name
                            claimInfo.claimValue = claim.value ?? ""
                            claimInfo.purpose = content.purposeForSharing ?? ""
                            history.claims.append(
                                claimInfo
                            )
                        }
                        let metadata = openIdProvider.authRequestProcessedData?.clientMetadata
                        history.rp = metadata?.clientId ?? ""
                        history.rpName = metadata?.clientName ?? ""
                        history.privacyPolicyURL = metadata?.policyUri ?? ""
                        history.logoURL = metadata?.logoUri ?? ""

                        storeManager.save(history: history)
                    }

                }

                if postResult.sharedIdToken != nil {
                    print("Saving id token history")
                    let storeManager = IdTokenSharingHistoryManager(container: nil)
                    var history = Datastore_IdTokenSharingHistory()
                    history.rp = openIdProvider.clientId!
                    history.accountIndex = Int32(account.index)
                    history.createdAt = Date().toGoogleTimestamp()
                    history.accountUseCase = account.accountUseCase.rawValue
                    history.thumbprint = account.thumbprint
                    storeManager.save(history: history)
                }
                return .success(postResult)
            case .failure(let error):
                print("Response Error: \(error)")
                return .failure(error)
        }

    }

    enum ShareIdTokenError: Error {
        case illegalOpenIdProviderState
        case illegalAccountState
        case illegalSeedState
        case accountManagerError
        case keyPairError
        case responseError
    }

}
