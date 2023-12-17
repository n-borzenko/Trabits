//
//  SettingsView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 07/12/2023.
//

import SwiftUI

class NavigationCoordinator: ObservableObject {
  @Published var path = NavigationPath()
}

struct SettingsView: View {
  enum SettingsContentType: String, CaseIterable {
    case habits = "Habits"
    case categories = "Categories"
    
    var itemTitle: String {
      switch self {
      case .habits: return "habit"
      case .categories: return "category"
      }
    }
  }
  
  @State private var selectedContentType = SettingsContentType.habits
  @State private var isHabitGroupingOn = false
  @State private var editMode: EditMode = .inactive
  @StateObject private var navigationCoordinator = NavigationCoordinator()
  
  @State private var isHabitEditorVisible = false
  @State private var isCategoryEditorVisible = false
  
  var body: some View {
    NavigationStack(path: $navigationCoordinator.path) {
      VStack {
        Picker("Type of content", selection: $selectedContentType) {
          ForEach(SettingsContentType.allCases, id: \.rawValue) { contentType in
            Text(contentType.rawValue)
              .tag(contentType)
          }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        
        Group {
          if selectedContentType == .habits && !isHabitGroupingOn {
            SettingsHabitsView()
          }
          if selectedContentType == .habits && isHabitGroupingOn {
            SettingsGroupedHabitsView()
          }
          if selectedContentType == .categories {
            SettingsCategoriesView()
          }
        }
        .environment(\.editMode, $editMode)
        .navigationDestination(for: Habit.self) { habit in
          SettingsHabitDetailView(habit: habit)
        }
        .navigationDestination(for: Category.self) { category in
          SettingsCategoryDetailView(category: category)
        }
      }
      .background(Color(uiColor: .systemBackground))
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .topBarLeading) {
          if selectedContentType == .habits && editMode == .inactive {
            Button(
              isHabitGroupingOn ? "Hide category groups" : "Group by category",
              systemImage: isHabitGroupingOn ? "rectangle.stack.fill" : "rectangle.stack"
            ) {
              isHabitGroupingOn.toggle()
            }
          }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
          if editMode == .inactive {
            Button("Add new \(selectedContentType.itemTitle)", systemImage: "plus") {
              switch selectedContentType {
              case .habits: isHabitEditorVisible = true
              case .categories: isCategoryEditorVisible = true
              }
            }
            if !isHabitGroupingOn || selectedContentType == .categories  {
              Button("Reorder \(selectedContentType.rawValue.lowercased())", systemImage: "arrow.up.arrow.down") {
                editMode = .active
              }
            }
          }
          if editMode == .active {
            Button("Done") {
              editMode = .inactive
            }
          }
        }
      }
      .onChange(of: selectedContentType) { _ in editMode = .inactive }
      .onDisappear { editMode = .inactive }
      .sheet(isPresented: $isHabitEditorVisible) {
        HabitEditorView()
      }
      .sheet(isPresented: $isCategoryEditorVisible) {
        CategoryEditorView()
      }
    }
    .environmentObject(navigationCoordinator)
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  return SettingsView()
    .environment(\.managedObjectContext, context)
}
