//
//  TitleSelectorView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 03/12/2023.
//

import SwiftUI

struct TitleSelectorView: View {
  @Binding var title: String
  @FocusState.Binding var focusedField: FocusedEditorField?

  var body: some View {
    Section("Title") {
      TextField("Title", text: $title)
        .focused($focusedField, equals: .title)
    }
  }
}

#Preview {
  List {
    TitleSelectorView(
      title: .constant("Title"),
      focusedField: FocusState<FocusedEditorField?>().projectedValue
    )
  }
}
