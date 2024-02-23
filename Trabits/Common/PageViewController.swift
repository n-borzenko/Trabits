//
//  PageViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 21/02/2024.
//

import UIKit

protocol AccessibilityPageScrollDelegate: AnyObject {
  func selectNextPage(direction: UIPageViewController.NavigationDirection) -> Bool
}

class PageViewController: UIPageViewController {
  weak var accessibilityScrollDelegate: AccessibilityPageScrollDelegate?

  override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
    guard let delegate = accessibilityScrollDelegate else { return false }
    var newDirection: UIPageViewController.NavigationDirection
    switch direction {
    case .left:
      newDirection = .forward
    case .right:
      newDirection = .reverse
    default:
      return false
    }
    return delegate.selectNextPage(direction: newDirection)
  }
}
