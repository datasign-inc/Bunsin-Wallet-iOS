//
//  SubmitCredentials.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/10/30.
//

import SwiftUI

struct SubmitCredentials: View {

    var credentials: [Credential?]

    @Environment(\.dismiss) private var dismiss
    @Environment(SigningRequestViewModel.self) private var signingRequestViewModel
    @State private var viewModel = SubmitCredentialsViewModel()

    @Binding var showSigningRequest: String?
    @Binding var path: [ScreensOnFullScreen]

    init(
        credentials: [Credential?],
        path: Binding<[ScreensOnFullScreen]>,
        showSigningRequest: Binding<String?>
    ) {
        self.credentials = credentials
        self._path = path
        self._showSigningRequest = showSigningRequest
    }

    fileprivate init(
        credentials: [Credential?],
        previewModel: SubmitCredentialsViewModel,
        path: Binding<[ScreensOnFullScreen]>,
        showSigingRequest: Binding<String?>
    ) {
        self.credentials = credentials
        self._viewModel = State(initialValue: previewModel)
        self._path = path
        self._showSigningRequest = showSigingRequest
    }

    private var headerView: some View {
        VStack(alignment: .leading) {
            Text("Check the information you provide")
                .font(.title2)
                .bold()
                .modifier(Title2Black())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
        }
    }

    private var claimsSection: some View {
        VStack {

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("ID generated by this app")
                            .padding(.bottom, 2)
                            .modifier(BodyBlack())
                    }
                    Spacer()
                    Text("required").padding(.horizontal, 8).foregroundColor(.red)
                }
            }
            .padding(.vertical, 6)  // 上下のpaddingに対応
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(viewModel.model.affiliationCredRequiredClaims, id: \.self.disclosure.id) { it in
                DisclosureRow(
                    vpMode: true,
                    submitDisclosure: .constant(it)
                )
            }
            if viewModel.model.affiliationCredUserSelectableClaims.count > 0 {
                ForEach(
                    $viewModel.model.affiliationCredUserSelectableClaims, id: \.self.disclosure.id
                ) { $claim in
                    DisclosureRow(
                        vpMode: true,
                        submitDisclosure: $claim
                    )
                }
            }
        }
    }

    private func openURLInExternalApp(urlString: String) {
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        else {
            print("invalid url is specified.")
        }
    }

    private var buttonSection: some View {
        VStack {
            ActionButtonBlack(
                title: "send",
                action: {
                    viewModel.model.locationAfterVp = nil
                    Task {
                        await viewModel.submitCredentials(
                            signingRequestViewModel: signingRequestViewModel
                        )
                    }
                }
            )
            .padding(.vertical, 16)
        }
    }

    private var organizationInfo: some View {
        return VStack(alignment: .leading, spacing: 0) {
            Text("recipient _organization_information")
                .font(.title3)
                .fontWeight(.light)
                .modifier(BodyGray())
                .padding(.bottom, 12)
            if let clientInfo = self.signingRequestViewModel.model.clientInfo {
                RecipientOrgInfo(
                    clientInfo: clientInfo
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せ
        .padding(.vertical, 16)
    }

    var body: some View {
        GeometryReader { _ in
            Group {
                ScrollView {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    else {
                        VStack {
                            headerView
                            claimsSection
                            organizationInfo
                                .padding(.top, 8)
                            buttonSection
                                .padding(.top, 8)
                        }.padding(.horizontal, 16)
                    }

                }
            }
        }.onAppear {
            Task {
                let presentationDefinition = signingRequestViewModel.presentationDefinition
                await viewModel.loadData(
                    credentials: credentials,
                    presentationDefinition: presentationDefinition,
                    isCommentVcRequired: signingRequestViewModel.isCommentVcRequired()
                )
            }
        }.alert(isPresented: $viewModel.model.showAlert) {
            Alert(
                title: Text(viewModel.model.alertTitle),
                message: Text(viewModel.model.alertMessage),
                dismissButton: .default(Text("OK")) {
                    path.removeAll()
                    showSigningRequest = nil
                    if let location = viewModel.model.locationAfterVp {
                        print("Open the redirect_uri in external browser: \(location)")
                        openURLInExternalApp(urlString: location)
                    }
                }
            )
        }
    }
}

#Preview("Affiliation and Comment") {
    SubmitCredentials(
        credentials: [dummyAffiliationCredential(), dummyCommentCredential()],
        previewModel: SubmitCredentialsPreviewModel(),
        path: .constant([]),
        showSigingRequest: .constant("")
    ).environment(dummySigningRequestViewModel())
}

#Preview("Comment only") {
    SubmitCredentials(
        credentials: [dummyCommentCredential()],
        previewModel: SubmitCredentialsPreviewModel(),
        path: .constant([]),
        showSigingRequest: .constant("")
    ).environment(dummySigningRequestViewModel())
}

func dummyAffiliationCredential() -> Credential {
    var dummyCredentialData = Datastore_CredentialData()
    dummyCredentialData.id = "2"
    dummyCredentialData.format = "vc+sd-jwt"
    dummyCredentialData.credential =
        "eyJ0eXAiOiJzZCtqd3QiLCJhbGciOiJFUzI1NiJ9.eyJ2Y3QiOiJhZmZpbGlhdGlvbl9jcmVkZW50aWFsIiwiX3NkIjpbIldQOFVTLU00X3IyaldFdmdsNVVldmhNYm1MRlB4S0s0UnFFRTJKLXhCcDAiLCJha25KVC1ZNGw5bWRCUS1nZlhyMU5LajVDOEZuT1M4a2J4U2ZHWVlDaHFFIiwiYkgySEpWODNaZ0NtWEZCZHM4YklQWEVOU0ZFYUxvRXlvX3JHeVBDS0dmVSJdLCJfc2RfYWxnIjoiU0hBLTI1NiJ9.UTeeKNNTCQWcns43mjQJ9k1S90jQ6NhzRiRN_p8nVD3yYf9KTeTLB95Tqhyb9LX_L7AhNh8Io7qdxTBEOedMaA~WyI5Mjk0MjE0OTEzZDkyMWNiIiwib3JnYW5pemF0aW9uX25hbWUiLCJFeGFtcGxlIGNvIGx0ZCJd~WyJiNTUxYzYwYzBkMzljYjlhIiwiZmFtaWx5X25hbWUiLCJkb2UiXQ~WyI5ODQyZWJkZWQzZTFjZTA1IiwiZ2l2ZW5fbmFtZSIsImpob24iXQ~"
    dummyCredentialData.cNonce = "CNonce1"
    dummyCredentialData.cNonceExpiresIn = 3600
    dummyCredentialData.iss = "Iss1"
    dummyCredentialData.iat = 1_638_290_000
    dummyCredentialData.exp = 1_638_293_600
    dummyCredentialData.type = "affiliation_credential"
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
                  "affiliation_credential": {
                    "format": "vc+sd-jwt",
                    "scope": "AffiliationCredentialScope",
                      "vct": "affiliation_credential",
                      "claims": {
                        "organization_name": {
                          "display": [
                            {
                              "name": "organization Name",
                              "locale": "en-US"
                            },
                            {
                              "name": "組織名",
                              "locale": "ja_JP"
                            }
                          ]
                        },
                        "family_name": {
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
                        "given_name": {
                          "display": [
                            {
                              "name": "GPA"
                            }
                          ]
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
    return dummyCredentialData.toCredential()!
}

func dummyCommentCredential() -> Credential {
    var dummyCredentialData = Datastore_CredentialData()
    dummyCredentialData.id = "1"
    dummyCredentialData.format = "jwt_vc_json"
    dummyCredentialData.credential =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiaWF0IjoxNTE2MjM5MDIyLCJ2YyI6eyJ0eXBlIjpbIkNvbW1lbnRDcmVkZW50aWFsIl0sImNyZWRlbnRpYWxTdWJqZWN0Ijp7InVybCI6Imh0dHBzOi8vZXhhbXBsZS5jb20vIiwiY29tbWVudCI6InRoaXMgaXMgY29tbWVudCIsImJvb2xfdmFsdWUiOjF9fX0.NjafpAIfqnbxiv4cpY_GmAmI9J2x1rrmueLMkGLa1Pw"
    dummyCredentialData.cNonce = "CNonce1"
    dummyCredentialData.cNonceExpiresIn = 3600
    dummyCredentialData.iss = "Iss1"
    dummyCredentialData.iat = 1_638_290_000
    dummyCredentialData.exp = 1_638_293_600
    dummyCredentialData.type = "CommentCredential"
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
                  "CommentCredential": {
                    "format": "jwt_vc_json",
                    "scope": "CommentCredentialScope",
                    "credential_definition": {
                      "type": [
                        "CommentCredential",
                        "VerifiableCredential"
                      ],
                      "credentialSubject": {
                        "comment": {
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
                        "url": {
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
                        "bool_value": {},
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
    return dummyCredentialData.toCredential()!
}

func dummySigningRequestViewModel() -> SigningRequestViewModel {

    let presentationDefinitionData = Data(
        """
                {
                  "id": "12345",
                  "submission_requirements": [
                    {
                      "name": "Comment submission",
                      "rule": "pick",
                      "count": 1,
                      "from": "COMMENT"
                    },
                    {
                      "name": "Affiliation info for your comment",
                      "rule": "pick",
                      "max": 1,
                      "from": "AFFILIATION"
                    }
                  ],
                  "input_descriptors": [
                    {
                      "id": "comment_input",
                      "group": [
                        "COMMENT"
                      ],
                      "format": {
                        "jwt_vc_json": {
                          "proof_type": [
                            "JsonWebSignature2020"
                          ]
                        }
                      },
                      "constraints": {
                        "limit_disclosure": "required",
                        "fields": [
                          {
                            "path": [
                              "$.vc.type"
                            ],
                            "filter": {
                              "type": "array",
                              "contains": {
                                "const": "CommentCredential"
                              }
                            }
                          },
                          {
                            "path": [
                              "$.vc.credentialSubject.comment"
                            ],
                            "filter": {
                              "type": "string",
                              "const": "This is comment！！"
                            }
                          },
                          {
                            "path": [
                              "$.vc.credentialSubject.url"
                            ],
                            "filter": {
                              "type": "string",
                              "const": "https://example.com/"
                            }
                          },
                          {
                            "path": [
                              "$.vc.credentialSubject.bool_value"
                            ],
                            "filter": {
                              "type": "string",
                              "const": "1"
                            }
                          }
                        ]
                      }
                    },
                    {
                      "id": "affiliation_input",
                      "group": [
                        "AFFILIATION"
                      ],
                      "format": {
                        "vc+sd-jwt": {}
                      },
                      "constraints": {
                        "fields": [
                          {
                            "path": [
                              "$.vct"
                            ],
                            "filter": {
                              "type": "string",
                              "const": "affiliation_credential"
                            }
                          },
                          {
                            "path": [
                              "$.organization_name"
                            ]
                          },
                          {
                            "path": [
                              "$.family_name"
                            ]
                          },
                          {
                            "path": [
                              "$.given_name"
                            ],
                            "optional": true
                          }
                        ]
                      }
                    }
                  ]
                }
        """.utf8)

    let decoder = JSONDecoder()
    let _ = decoder.keyDecodingStrategy = .convertFromSnakeCase
    let pd = try! decoder.decode(PresentationDefinition.self, from: presentationDefinitionData)

    let signingRequestViewModel = SigningRequestViewModel()
    let _ = signingRequestViewModel.presentationDefinition = pd
    let _ =
        signingRequestViewModel.model.clientInfo = ClientInfo(
            clientId: "https://boolcheck.com",
            name: "Boolcheck",
            logoUrl: "https://www.ownd-project.com/img/logo_only.png",
            policyUrl: "https://boolcheck.example.com/policy",
            tosUrl: "https://boolcheck.example.com/tos",
            certificateInfo:
                CertificateInfo(
                    domain: "ownd-project.com",
                    organization: "DataSign Inc.",
                    locality: "",
                    state: "Tokyo",
                    country: "JP",
                    street: "",
                    email: "support@ownd-project.com",
                    issuer:
                        CertificateInfo(
                            domain: "Sectigo ECC Organization Validation Secure Server CA",
                            organization: "Sectigo Limited",
                            locality: "Salford",
                            state: "Greater Manchester",
                            country: "GB",
                            street: "",
                            email: "support@ownd-project.com",
                            issuer: nil
                        )
                )
        )

    return signingRequestViewModel
}
