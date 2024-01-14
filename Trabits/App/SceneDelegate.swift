//
//  SceneDelegate.swift
//  Trabits
//
//  Created by Natalia Borzenko on 19/06/2023.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    window = UIWindow(frame: windowScene.coordinateSpace.bounds)
    window?.windowScene = windowScene
    
    let tabBarAppearance = UITabBarAppearance()
    tabBarAppearance.configureWithOpaqueBackground()
    tabBarAppearance.backgroundColor = .systemBackground
    UITabBar.appearance().standardAppearance = tabBarAppearance
    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

    let tabBarViewController = UITabBarController()
    
    let trackerContainerViewController = UINavigationController(rootViewController: TrackerContainerViewController())
    trackerContainerViewController.navigationBar.prefersLargeTitles = false
    trackerContainerViewController.tabBarItem = UITabBarItem(title: "Tracker", image: UIImage(systemName: "checklist"), tag: 0)
    tabBarViewController.addChild(trackerContainerViewController)
    
    let settingsView = SettingsView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    let settingsViewController = UIHostingController(rootView: settingsView)
    settingsViewController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape.fill"), tag: 1)
    tabBarViewController.addChild(settingsViewController)
    
    let lineBorderView = UIView()
    lineBorderView.backgroundColor = .neutral30
    lineBorderView.translatesAutoresizingMaskIntoConstraints = false
    tabBarViewController.tabBar.addSubview(lineBorderView)
    
    lineBorderView.topAnchor.constraint(equalTo: tabBarViewController.tabBar.topAnchor).isActive = true
    lineBorderView.leadingAnchor.constraint(equalTo: tabBarViewController.tabBar.leadingAnchor).isActive = true
    lineBorderView.trailingAnchor.constraint(equalTo: tabBarViewController.tabBar.trailingAnchor).isActive = true
    lineBorderView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
    
    window?.rootViewController = tabBarViewController
    window?.makeKeyAndVisible()
  }

  func sceneDidDisconnect(_ scene: UIScene) { }

  func sceneDidBecomeActive(_ scene: UIScene) { }

  func sceneWillResignActive(_ scene: UIScene) { }

  func sceneWillEnterForeground(_ scene: UIScene) { }

  func sceneDidEnterBackground(_ scene: UIScene) {
    PersistenceController.shared.saveContext()
  }
}

