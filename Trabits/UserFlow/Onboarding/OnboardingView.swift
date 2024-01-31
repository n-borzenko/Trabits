//
//  OnboardingView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 31/01/2024.
//

import SwiftUI

struct OnboardingItem: Identifiable {
  let imageName: String
  let message: String
  
  var id: String { imageName }
}

struct OnboardingView: View {
  private let items = [
    OnboardingItem(imageName: "OnboardingActivities", message: "Complete tasks every day"),
    OnboardingItem(imageName: "OnboardingTracking", message: "Track your progress daily"),
    OnboardingItem(imageName: "OnboardingAchievements", message: "Evaluate your achievements"),
    OnboardingItem(imageName: "OnboardingCelebration", message: "Celebrate your improvement")
  ]
  
  @State private var selectedTab = 0
  
  var body: some View {
    VStack {
      TabView(selection: $selectedTab) {
        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
          VStack {
            Spacer()
            HStack {
              Spacer()
              Image(item.imageName)
                .resizable()
                .scaledToFit()
                .frame(minWidth: 32, minHeight: 32)
              Spacer()
            }
            Spacer()
            Text(item.message)
              .font(.headline)
              .multilineTextAlignment(.center)
              .padding(.bottom)
              .minimumScaleFactor(0.8)
              .padding(.bottom)
            Spacer()
          }
          .tag(index)
          .padding(.bottom, 24)
          .padding(.horizontal)
        }
      }
      .tabViewStyle(.page)
      .indexViewStyle(.page(backgroundDisplayMode: .always))
      .animation(.easeOut(duration: 0.5), value: selectedTab)
      
      HStack {
        Spacer()
        if selectedTab == items.count - 1 {
          Button("Start") {
            UserDefaults.standard.wasOnboardingShown = true
          }
          .buttonStyle(.borderedProminent)
          .foregroundColor(.inverted)
        } else {
          Button("Next") {
            selectedTab += 1
          }
          .buttonStyle(.bordered)
        }
        Spacer()
      }
      .padding(.bottom)
    }
  }
}

#Preview {
  OnboardingView()
}
