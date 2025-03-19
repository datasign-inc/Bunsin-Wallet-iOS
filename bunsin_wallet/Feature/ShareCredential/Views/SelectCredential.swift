//
//  SelectCredential.swift
//  bunsin_wallet
//
//  Created by katsuyoshi ozaki on 2024/10/28.
//

import SwiftUI

extension List {
    fileprivate func credentialListBackground(_ color: Color) -> some View {
        UITableView.appearance().backgroundColor = UIColor(color)
        return self
    }
}

struct SelectCredential: View {

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SelectCredentialViewModel()
    @Binding var path: [ScreensOnFullScreen]

    var presentationDefinition: PresentationDefinition?

    init(
        presentationDefinition: PresentationDefinition?,
        path: Binding<[ScreensOnFullScreen]>
    ) {
        self._path = path
        self.presentationDefinition = presentationDefinition
    }

    fileprivate init(
        previewModel: SelectCredentialViewModel,
        presentationDefinition: PresentationDefinition?,
        path: Binding<[ScreensOnFullScreen]>
    ) {
        self._viewModel = State(initialValue: previewModel)
        self._path = path
        self.presentationDefinition = presentationDefinition
    }

    private var headerView: some View {
        VStack(alignment: .leading) {
            Text("select_a_certificate")
                .font(.title2)
                .bold()
                .modifier(Title2Black())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
        }

    }

    private var notification: some View {
        VStack(alignment: .leading) {
            Text("choose_certificate_to_prove_identity")
                .padding(.bottom, 8)
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "info.circle")  // インフォメーションアイコン
                    .foregroundColor(.gray)
                    .font(.system(size: 20))

                Text("can_be_edited_on_the_next_screen")
                    .multilineTextAlignment(.leading)
                    .font(.body)
                    .modifier(BodyGray())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(hex: 0xf2f2f7))
            .cornerRadius(8)

        }.padding(.top, 2)

    }

    private func credentialList() -> some View {
        VStack {
            List {
                ForEach(self.viewModel.model.credentialChoices, id: \.1.self) {
                    (name, credential) in
                    radioButtonCell(
                        credentialName: name,
                        credential: credential
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.viewModel.updateSelectedCredential(selectedCredential: credential)
                    }
                }.contentShape(Rectangle())
                    .listRowBackground(
                        Color(UIColor.secondarySystemGroupedBackground)
                            .overlay(alignment: .bottom) {
                                Divider()
                            }
                    )
            }.credentialListBackground(.white)
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.gray, lineWidth: 1)
                )
                .environment(\.defaultMinListRowHeight, 0)
        }
    }

    private func radioButtonCell(credentialName: String, credential: Credential?) -> some View {
        return HStack {
            Image(systemName: self.viewModel.getRadioButtonImage(credential: credential))
                .font(.system(size: 20))
                .foregroundColor(self.viewModel.getRadioButtonColor(credential: credential))
            VStack(alignment: .leading) {
                Text(credentialName)
                    .font(.system(size: 20))
                if let cred = credential {
                    Text(String(localized: "Issuer") + cred.issuerDisplayName)
                }
            }
            Spacer()
        }
    }

    var nextButton: some View {
        VStack {
            ActionButtonBlack(
                title: "Proceed to next",
                action: {
                    path.append(
                        ScreensOnFullScreen.submitCredential(
                            self.viewModel.model.selectedCredential))
                }
            )
            .padding(.vertical, 8)
        }
    }

    var body: some View {

        GeometryReader { _ in
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                else {
                    VStack {
                        headerView
                        notification
                        credentialList()
                        nextButton
                    }.padding(.horizontal, 16)
                }
            }
        }
        .onAppear {
            Task {
                await self.viewModel.loadData(
                    presentationDefinition: presentationDefinition)
            }
        }.alert(isPresented: $viewModel.model.showAlert) {
            Alert(
                title: Text(viewModel.model.alertTitle),
                message: Text(viewModel.model.alertMessage),
                dismissButton: .default(Text("OK")) {
                    self.dismiss()
                }
            )
        }
    }
}

extension Color {
    fileprivate init(hex: Int, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
}

/*
#Preview("Default") {
    let presentationDefinition = ... // todo

    SelectCredential(
        previewModel: SelectCredentialPreviewModel(),
        presentationDefinition: presentationDefinition,
        path: .constant([])
    )
}
*/
