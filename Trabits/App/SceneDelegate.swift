//
//  SceneDelegate.swift
//  Trabits
//
//  Created by Natalia Borzenko on 19/06/2023.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    window = UIWindow(frame: windowScene.coordinateSpace.bounds)
    window?.windowScene = windowScene

    let tabBarViewController = UITabBarController()
    
    let trackerContainerViewController = UINavigationController(rootViewController: TrackerContainerViewController())
    trackerContainerViewController.navigationBar.prefersLargeTitles = false
    trackerContainerViewController.tabBarItem = UITabBarItem(title: "Tracker", image: UIImage(systemName: "checklist.unchecked"), tag: 0)
    tabBarViewController.addChild(trackerContainerViewController)

    let trackerViewController = UINavigationController(rootViewController: TrackerViewController())
    trackerViewController.navigationBar.prefersLargeTitles = true
    trackerViewController.tabBarItem = UITabBarItem(title: "Tracker", image: UIImage(systemName: "checklist.unchecked"), tag: 1)
    tabBarViewController.addChild(trackerViewController)
    
    let trackerViewController2 = UINavigationController(rootViewController: TrackerViewController2())
    trackerViewController2.navigationBar.prefersLargeTitles = true
    trackerViewController2.tabBarItem = UITabBarItem(title: "Tracker", image: UIImage(systemName: "checklist.unchecked"), tag: 2)
    tabBarViewController.addChild(trackerViewController2)

    let settingsListViewController = UINavigationController(rootViewController: HabitsListViewController())
    settingsListViewController.navigationBar.prefersLargeTitles = true
    settingsListViewController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "rectangle.stack.fill"), tag: 3)
    tabBarViewController.addChild(settingsListViewController)
    
    let todayViewController = UINavigationController(rootViewController: TodayViewController())
    todayViewController.navigationBar.prefersLargeTitles = true
    todayViewController.tabBarItem = UITabBarItem(title: "Today", image: UIImage(systemName: "checklist.unchecked"), tag: 4)
    tabBarViewController.addChild(todayViewController)

    window?.rootViewController = tabBarViewController
    window?.makeKeyAndVisible()
  }

  func sceneDidDisconnect(_ scene: UIScene) { }

  func sceneDidBecomeActive(_ scene: UIScene) { }

  func sceneWillResignActive(_ scene: UIScene) { }

  func sceneWillEnterForeground(_ scene: UIScene) { }

  func sceneDidEnterBackground(_ scene: UIScene) {
    (UIApplication.shared.delegate as? AppDelegate)?.coreDataStack.saveContext()
  }
}

