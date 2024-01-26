//
//  SettingsAboutView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 23/01/2024.
//

import SwiftUI

struct SettingsAboutView: View {
  
  var body: some View {
    List {
      Section("Contacts") {
        LabeledContent {
          Link("trabits.nborzenko.me", destination: URL(string: "https://www.trabits.nborzenko.me/")!)
            .tint(.secondary)
        } label: {
          Text("Webpage")
        }
        LabeledContent("Developer", value: "Natalia Borzenko")
        LabeledContent {
          Link("n.borzenko93@gmail.com", destination: URL(string: "mailto:n.borzenko93@gmail.com")!)
            .tint(.secondary)
        } label: {
          Text("Email")
        }
      }
      Section("Images") {
        Text("Images in the application were created with \"Image Creator from Microsoft Designer\".")
          .font(.headline)
          .padding(.vertical, 6)
      }
      .listStyle(.insetGrouped)
      .navigationTitle("About")
    }
  }
}

#Preview {
  SettingsAboutView()
}
