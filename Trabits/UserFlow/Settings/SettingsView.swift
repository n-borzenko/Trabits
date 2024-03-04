//
//  SettingsView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 23/01/2024.
//

import SwiftUI

struct SettingsItemView: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize
  var imageName: String
  var colorIndex: Int
  var title: String
  var value: String?

  var body: some View {
    let squareSize: Double = dynamicTypeSize < .accessibility1 ? 28 : 40

    LabeledContent {
      Text(value ?? "")
    } label: {
      HStack {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(Color(uiColor: PastelPalette.colors[colorIndex]))
          .frame(width: squareSize, height: squareSize)
          .padding(4)
          .overlay {
            Image(systemName: imageName)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .foregroundColor(.white)
              .padding(10)
          }
        Text(title)
      }
    }
  }
}

enum SettingsPath {
  case about
  case userData
}

struct SettingsView: View {
  @EnvironmentObject var settingsRouter: SettingsRouter

  var body: some View {
    NavigationStack(path: $settingsRouter.path) {
      List {
        Section("Storage") {
          NavigationLink(value: SettingsPath.userData) {
            SettingsItemView(imageName: "lock", colorIndex: 9, title: "User data")
          }
        }
        Section("Application") {
          SettingsItemView(
            imageName: "pencil.and.outline",
            colorIndex: 4,
            title: "Current version",
            value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
          )
          NavigationLink(value: SettingsPath.about) {
            SettingsItemView(imageName: "info.circle", colorIndex: 14, title: "About")
          }
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(for: SettingsPath.self) { destination in
        switch destination {
        case .about: SettingsAboutView()
        case .userData: SettingsUserDataView()
        }
      }
    }
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  let settingsRouter = SettingsRouter()
  return SettingsView()
    .environment(\.managedObjectContext, context)
    .environmentObject(settingsRouter)
}
