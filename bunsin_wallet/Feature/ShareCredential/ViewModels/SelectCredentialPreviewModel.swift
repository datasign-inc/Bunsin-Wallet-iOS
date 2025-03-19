//
//  SelectCredentialPreviewModel.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/10/28.
//

class SelectCredentialPreviewModel: SelectCredentialViewModel {

    override func loadData(presentationDefinition: PresentationDefinition?) async {
        isLoading = true
        print("load dummy data..")

        var dummyCredentialData = Datastore_CredentialData()
        dummyCredentialData.id = "1"
        dummyCredentialData.format = "jwt_vc_json"
        dummyCredentialData.credential =
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJ2YyI6eyJ0eXBlIjpbIlR5cGUxIl0sImNyZWRlbnRpYWxTdWJqZWN0Ijp7Im5hbWUiOiJqaG9uIHNtaXRoIn19fQ.oJgBUQB_YHrRwMeXjpLPvdvuXEFNgFfnq6iJEa-Lapw"
        dummyCredentialData.cNonce = "CNonce1"
        dummyCredentialData.cNonceExpiresIn = 3600
        dummyCredentialData.iss = "Iss1"
        dummyCredentialData.iat = 1_638_290_000
        dummyCredentialData.exp = 1_638_293_600
        dummyCredentialData.type = "Type1"
        dummyCredentialData.accessToken = "AccessToken1"
        dummyCredentialData.credentialIssuerMetadata = """
            {
                    "credential_issuer": "https://datasign-demo-vci.tunnelto.dev",
                    "authorization_servers": [
                      "https://datasign-demo-vci.tunnelto.dev"
                    ],
                    "credential_endpoint": "https://datasign-demo-vci.tunnelto.dev/credentials",
                    "batch_credential_endpoint": "https://datasign-demo-vci.tunnelto.dev/batch-credentials",
                    "deferred_credential_endpoint": "https://datasign-demo-vci.tunnelto.dev/deferred_credential",
                    "display": [
                      {
                        "name": "OWND Project",
                        "locale": "en-US",
                        "logo": {
                          "uri": "https://exampleuniversity.com/public/logo.png",
                          "alt_text": "a square logo of a university"
                        }
                      }
                    ],
                    "credential_configurations_supported": {
                      "Type1": {
                        "format": "jwt_vc_json",
                        "scope": "UniversityDegree",
                        "credential_definition": {
                          "type": [
                            "IdentityCredential",
                            "VerifiableCredential"
                          ],
                          "credentialSubject": {
                            "given_name": {
                              "display": [
                                {
                                  "name": "Given Name",
                                  "locale": "en-US"
                                },
                                {
                                  "name": "名",
                                  "locale": "ja_JP"
                                }
                              ]
                            },
                            "last_name": {
                              "display": [
                                {
                                  "name": "Surname",
                                  "locale": "en-US"
                                },
                                {
                                  "name": "姓",
                                  "locale": "ja_JP"
                                }
                              ]
                            },
                            "degree": {},
                            "gpa": {
                              "display": [
                                {
                                  "name": "GPA"
                                }
                              ]
                            }
                          }
                        },
                        "proof_types_supported": {
                          "jwt": {
                              "proof_signing_alg_values_supported": [
                                  "ES256"
                              ]
                          }
                        },
                        "display": [
                          {
                            "name": "IdentityCredential",
                            "locale": "ja_JP",
                            "logo": {
                              "uri": "https://exampleuniversity.com/public/logo.png",
                              "alt_text": "a square logo of a university"
                            },
                            "background_color": "#12107c",
                            "text_color": "#FFFFFF"
                          }
                        ]
                      }
                    }
                  }
            """
        let dummy = dummyCredentialData.toCredential()

        model.credentialChoices = [
            ("Credential A", dummy!),
            (String(localized: "post_without_affiliation_certificate"), nil),
        ]

        isLoading = false
    }
}
