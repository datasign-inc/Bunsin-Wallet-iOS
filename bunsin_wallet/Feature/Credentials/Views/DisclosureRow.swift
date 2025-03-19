//
//  DisclosureLow.swift
//  bunsin_wallet
//
//  Created by SadamuMatsuoka on 2023/12/26.
//

import SwiftUI

struct DisclosureRow: View {

    var vpMode: Bool
    @Binding var submitDisclosure: DisclosureWithOptionality  //(key: String, value: String)

    private func lightGrayText(key: String, value: String) -> some View {
        return VStack(alignment: .leading) {
            Text(LocalizedStringKey(key))
                .fontWeight(.light)
                .modifier(BodyGray())
                .padding(.bottom, 4)
            if value.starts(with: "data:image/") {
                Base64ImageView(base64String: value)
            }
            else {
                Text(value)
                    .padding(.bottom, 2)
                    .modifier(BodyLightGray())
            }
        }
    }

    private func blackText(key: String, value: String) -> some View {
        return VStack(alignment: .leading) {
            Text(LocalizedStringKey(key))
                .fontWeight(.light)
                .modifier(BodyGray())
                .padding(.bottom, 4)
            if value.starts(with: "data:image/") {
                Base64ImageView(base64String: value)
            }
            else {
                Text(value)
                    .padding(.bottom, 2)
                    .modifier(BodyBlack())
            }
        }
    }

    var body: some View {
        if let key = submitDisclosure.disclosure.key,
            let value = submitDisclosure.disclosure.value
        {
            let localizedKey = submitDisclosure.disclosure.localizedKey
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading) {
                        if vpMode {
                            if submitDisclosure.isSubmit {
                                blackText(key: localizedKey ?? key, value: value)
                            }
                            else {
                                lightGrayText(key: localizedKey ?? key, value: value)
                            }
                        }
                        else {
                            blackText(key: localizedKey ?? key, value: value)
                        }
                    }
                    if submitDisclosure.isUserSelectable {
                        Spacer()
                        Toggle("", isOn: $submitDisclosure.isSubmit).labelsHidden()
                    }
                    else {
                        if vpMode {
                            Spacer()
                            Text("required").padding(.horizontal, 8).foregroundColor(.red)
                        }
                    }
                }
            }
            .padding(.vertical, 6)  // 上下のpaddingに対応
            .frame(maxWidth: .infinity, alignment: .leading)
        }

    }
}

#Preview("1 vpMode = true, required claim") {
    let modelData = ModelData()
    modelData.loadCredentials()
    let disclosure = modelData.credentials.first?.disclosure?.first
    return DisclosureRow(
        vpMode: true,
        submitDisclosure:
            .constant(
                DisclosureWithOptionality(
                    disclosure: Disclosure(
                        disclosure: nil,
                        key: disclosure?.key,
                        value: disclosure?.value
                    ),
                    isSubmit: true,
                    isUserSelectable: false
                )))
}

#Preview("2. vpMode = true, optional off") {
    let modelData = ModelData()
    modelData.loadCredentials()
    let disclosure = modelData.credentials.first?.disclosure?.first
    return DisclosureRow(
        vpMode: true,
        submitDisclosure:
            .constant(
                DisclosureWithOptionality(
                    disclosure: Disclosure(
                        disclosure: nil, key: disclosure?.key, value: disclosure?.value),
                    isSubmit: false,
                    isUserSelectable: true
                ))
    )
}

#Preview("2. vpMode=true, optional on") {
    let modelData = ModelData()
    modelData.loadCredentials()
    let disclosure = modelData.credentials.first?.disclosure?.first
    return DisclosureRow(
        vpMode: true,
        submitDisclosure:
            .constant(
                DisclosureWithOptionality(
                    disclosure: Disclosure(
                        disclosure: nil, key: disclosure?.key, value: disclosure?.value),
                    isSubmit: true,
                    isUserSelectable: true
                ))
    )
}

#Preview("1 vpMode = false, required claim") {
    let modelData = ModelData()
    modelData.loadCredentials()
    let disclosure = modelData.credentials.first?.disclosure?.first
    return DisclosureRow(
        vpMode: false,
        submitDisclosure:
            .constant(
                DisclosureWithOptionality(
                    disclosure: Disclosure(
                        disclosure: nil,
                        key: disclosure?.key,
                        value: disclosure?.value
                    ),
                    isSubmit: true,
                    isUserSelectable: false
                )))
}
