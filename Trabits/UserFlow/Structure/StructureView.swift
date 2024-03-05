//
//  StructureView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 07/12/2023.
//

import SwiftUI

struct StructureView: View {
  @EnvironmentObject var structureRouter: StructureRouter
  @StateObject private var userDefaultsObserver = UserDefaultsObserver()

  @State private var isHabitEditorVisible = false
  @State private var isCategoryEditorVisible = false

  var body: some View {
    NavigationStack(path: $structureRouter.path) {
      VStack {
        Picker("Type of content", selection: $structureRouter.selectedContentType) {
          ForEach(StructureContentType.allCases, id: \.rawValue) { contentType in
            Text(contentType.rawValue)
              .tag(contentType)
          }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)

        Group {
          if structureRouter.selectedContentType == .habits && !userDefaultsObserver.isHabitGroupingOn {
            StructureHabitsView(isHabitEditorVisible: $isHabitEditorVisible)
          }
          if structureRouter.selectedContentType == .habits && userDefaultsObserver.isHabitGroupingOn {
            StructureGroupedHabitsView(isHabitEditorVisible: $isHabitEditorVisible)
          }
          if structureRouter.selectedContentType == .categories {
            StructureCategoriesView(isCategoryEditorVisible: $isCategoryEditorVisible)
          }
        }
        .environment(\.editMode, $structureRouter.editMode)
        .navigationDestination(for: Habit.self) { habit in
          StructureHabitDetailView(habit: habit)
        }
        .navigationDestination(for: Category.self) { category in
          StructureCategoryDetailView(category: category)
        }
      }
      .background(Color(uiColor: .systemBackground))
      .navigationTitle("My Habits")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .topBarLeading) {
          if structureRouter.selectedContentType == .habits && structureRouter.editMode == .inactive {
            Button(
              userDefaultsObserver.isHabitGroupingOn ? "Hide category groups" : "Group by category",
              systemImage: userDefaultsObserver.isHabitGroupingOn ? "folder.fill" : "folder"
            ) {
              UserDefaults.standard.isHabitGroupingOn = !userDefaultsObserver.isHabitGroupingOn
            }
          }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
          if structureRouter.editMode == .inactive {
            Button("Add new \(structureRouter.selectedContentType.itemTitle)", systemImage: "plus") {
              switch structureRouter.selectedContentType {
              case .habits: isHabitEditorVisible = true
              case .categories: isCategoryEditorVisible = true
              }
            }
            if !userDefaultsObserver.isHabitGroupingOn || structureRouter.selectedContentType == .categories {
              Button(
                "Reorder \(structureRouter.selectedContentType.rawValue.lowercased())",
                systemImage: "arrow.up.arrow.down"
              ) {
                structureRouter.editMode = .active
              }
            }
          }
          if structureRouter.editMode == .active {
            Button("Done") {
              structureRouter.editMode = .inactive
            }
          }
        }
      }
      .onChange(of: structureRouter.selectedContentType) { _ in structureRouter.editMode = .inactive }
      .onDisappear { structureRouter.editMode = .inactive }
      .fullScreenCover(isPresented: $isHabitEditorVisible) {
        HabitEditorView()
      }
      .fullScreenCover(isPresented: $isCategoryEditorVisible) {
        CategoryEditorView()
      }
    }
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  let structureRouter = StructureRouter()
  return StructureView()
    .environment(\.managedObjectContext, context)
    .environmentObject(structureRouter)
}
