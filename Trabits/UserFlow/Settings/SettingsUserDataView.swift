//
//  SettingsUserDataView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 23/01/2024.
//

import SwiftUI
import Combine

struct SettingsDataHabitsView: View {
  @FetchRequest(
    sortDescriptors: [
      SortDescriptor(\.archivedAt, order: .forward),
      SortDescriptor(\.order, order: .forward)
    ]
  )
  private var habits: FetchedResults<Habit>
  
  var body: some View {
    LabeledContent("Habit records:", value: "\(habits.count)")
  }
}

struct SettingsDataDayResultsView: View {
  @FetchRequest(sortDescriptors: [SortDescriptor(\.date, order: .forward)])
  private var dayResults: FetchedResults<DayResult>
  
  var body: some View {
    LabeledContent("Day result records:", value: "\(dayResults.count)")
  }
}

struct SettingsDataDayTargetsView: View {
  @FetchRequest(sortDescriptors: [SortDescriptor(\.applicableFrom, order: .forward)])
  private var dayTargets: FetchedResults<DayTarget>
  
  var body: some View {
    LabeledContent("Day target records:", value: "\(dayTargets.count)")
  }
}

struct SettingsDataWeekGoalsView: View {
  @FetchRequest(sortDescriptors: [SortDescriptor(\.applicableFrom, order: .forward)])
  private var weekGoals: FetchedResults<WeekGoal>
  
  var body: some View {
    LabeledContent("Week goal records:", value: "\(weekGoals.count)")
  }
}

struct SettingsDataCategoriesView: View {
  @FetchRequest(sortDescriptors: [SortDescriptor(\.order, order: .forward)])
  private var categories: FetchedResults<Category>
  
  var body: some View {
    LabeledContent("Category records:", value: "\(categories.count)")
  }
}

@MainActor
class UserDefaultsDataObserver: ObservableObject {
  @Published var count = 0
  
  private var cancellables = Set<AnyCancellable>()
  
  init() {
    UserDefaults.standard
      .publisher(for: \.isHabitGroupingOn)
      .sink { [weak self] _ in
        self?.updateCounter()
      }
      .store(in: &cancellables)
    
    UserDefaults.standard
      .publisher(for: \.wasOnboardingShown)
      .sink { [weak self] _ in
        self?.updateCounter()
      }
      .store(in: &cancellables)
  }
  
  private func updateCounter() {
    var count = 0
    count += UserDefaults.standard.hasData(for: .isHabitGroupingOnKey) ? 1 : 0
    count += UserDefaults.standard.hasData(for: .wasOnboardingShown) ? 1 : 0
    self.count = count
  }
  
  deinit {
    cancellables.forEach { $0.cancel() }
    cancellables.removeAll()
  }
}

struct SettingsUserDataView: View {
  @Environment(\.managedObjectContext) var context
  @StateObject private var userDefaultsCounter = UserDefaultsDataObserver()
  @State private var isDataDeletionAlertIsVisible = false
  @State private var isDataDeletionInProgress = false
  @State private var storedSettingsNumber = 0
  
  var body: some View {
    List {
      Section {
        Text("All user data is stored on the device and is never shared with any server or third-party service. We do not use cookies or collect anonymous statistics. In the event that conditions outlined above undergo any changes, user will be notified.")
          .font(.headline)
          .padding(.vertical, 6)
      }
      Section("User settings") {
        Text("Application state settings are stored in UserDefaults")
          .font(.headline)
          .padding(.vertical, 6)
        LabeledContent("Number of stored records:", value: "\(userDefaultsCounter.count)")
      }
      Section("Habits, categories, completions") {
        Text("User data is stored within a local SQLite database")
          .font(.headline)
          .padding(.vertical, 6)
        SettingsDataHabitsView()
        SettingsDataDayResultsView()
        SettingsDataDayTargetsView()
        SettingsDataWeekGoalsView()
        SettingsDataCategoriesView()
      }
      Section {
        Button("Delete all user data", role: .destructive) {
          isDataDeletionAlertIsVisible = true
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .alert("Delete user data", isPresented: $isDataDeletionAlertIsVisible) {
          Button("Cancel", role: .cancel) { }
          Button("Delete", role: .destructive, action: deleteAllData)
        }
      }
      .listStyle(.insetGrouped)
    }
    .overlay {
      SettingsProgressView(isDataDeletionInProgress: $isDataDeletionInProgress)
    }
    .navigationTitle("User data")
  }
  
  private func deleteAllData() {
    isDataDeletionInProgress = true
    
    // remove all core data objects
    do {
      let habitsFetchRequest = Habit.orderedHabitsFetchRequest()
      let habits = try context.fetch(habitsFetchRequest)
      habits.forEach { context.delete($0) }
      
      let categoriesFetchRequest = Category.orderedCategoriesFetchRequest()
      let categories = try context.fetch(categoriesFetchRequest)
      categories.forEach { context.delete($0) }
      
      try context.save()
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
    
    // remove user defaults data
    UserDefaults.standard.removeData(for: .isHabitGroupingOnKey)
    UserDefaults.standard.removeData(for: .wasOnboardingShown)
    
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
      isDataDeletionInProgress = false
      UIAccessibility.post(notification: .pageScrolled, argument: "All user data has been deleted")
    }
  }
}

struct SettingsProgressView: View {
  @Binding var isDataDeletionInProgress: Bool
  @State private var rotationAngle = 0.0
  
  var body: some View {
    Group {
      if isDataDeletionInProgress {
        VStack {
          Text("Deleting data")
            .font(.title2)
            .padding()
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(uiColor: .secondarySystemBackground))
            .frame(width: 60, height: 60)
            .overlay {
              Image(systemName: "arrow.triangle.2.circlepath")
                .resizable()
                .scaledToFit()
                .foregroundColor(.contrast)
                .padding()
                .rotationEffect(.degrees(rotationAngle))
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: false), value: rotationAngle)
            }
        }
        .padding()
        .background(Color(uiColor: .tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(radius: 2)
      }
    }
    .accessibilityHidden(true)
    .onChange(of: isDataDeletionInProgress) { _ in
      rotationAngle = isDataDeletionInProgress ? 360 : 0
    }
  }
}


#Preview {
  let context = PersistenceController.preview.container.viewContext
  return SettingsUserDataView()
    .environment(\.managedObjectContext, context)
}
