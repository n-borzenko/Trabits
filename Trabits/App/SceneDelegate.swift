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

    let habitsListViewController = UINavigationController(rootViewController: HabitsListViewController())
    habitsListViewController.navigationBar.prefersLargeTitles = true
    habitsListViewController.tabBarItem = UITabBarItem(title: "Habits", image: UIImage(systemName: "rectangle.stack.fill"), tag: 0)
    tabBarViewController.addChild(habitsListViewController)

    let todayViewController = TodayViewController()
    todayViewController.tabBarItem = UITabBarItem(title: "Today", image: UIImage(systemName: "calendar"), tag: 1)
    tabBarViewController.addChild(todayViewController)

    let categoriesViewController = UINavigationController(rootViewController: CategoriesViewController())
    categoriesViewController.navigationBar.prefersLargeTitles = true
    categoriesViewController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 2)
    tabBarViewController.addChild(categoriesViewController)

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

