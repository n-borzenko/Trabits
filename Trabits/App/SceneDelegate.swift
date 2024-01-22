//
//  SceneDelegate.swift
//  Trabits
//
//  Created by Natalia Borzenko on 19/06/2023.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var appCoordinator: AppCoordinator?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    let window = UIWindow(frame: windowScene.coordinateSpace.bounds)
    window.windowScene = windowScene
    appCoordinator = AppCoordinator(window: window)
    window.makeKeyAndVisible()
  }

  func sceneDidDisconnect(_ scene: UIScene) { }

  func sceneDidBecomeActive(_ scene: UIScene) { }

  func sceneWillResignActive(_ scene: UIScene) { }

  func sceneWillEnterForeground(_ scene: UIScene) { }

  func sceneDidEnterBackground(_ scene: UIScene) {
    PersistenceController.shared.saveContext()
  }
}

