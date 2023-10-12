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

    let settingsListViewController = UINavigationController(rootViewController: HabitsListViewController())
    settingsListViewController.navigationBar.prefersLargeTitles = true
    settingsListViewController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "rectangle.stack.fill"), tag: 1)
    tabBarViewController.addChild(settingsListViewController)

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

