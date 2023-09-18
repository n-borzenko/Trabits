//
//  UIColorValueTransformer.swift
//  Trabits
//
//  Created by Natalia Borzenko on 24/06/2023.
//

import UIKit

@objc(UIColorValueTransformer)
final class UIColorValueTransformer: ValueTransformer {
  override class func transformedValueClass() -> AnyClass {
    UIColor.self
  }

  override class func allowsReverseTransformation() -> Bool {
    true
  }

  override func transformedValue(_ value: Any?) -> Any? {
    guard let color = value as? UIColor else {
      return nil
    }

    do {
      let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
      return data
    } catch {
      fatalError("transformation error")
    }
  }

  override func reverseTransformedValue(_ value: Any?) -> Any? {
    guard let data = value as? Data else {
      return nil
    }

    do {
      let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
      return color
    } catch {
      fatalError("transformation error")
    }
  }
}

extension UIColorValueTransformer {
  static let name = NSValueTransformerName(rawValue: String(describing: UIColorValueTransformer.self))
  
  static func register() {
    let transformer = UIColorValueTransformer()
    ValueTransformer.setValueTransformer(transformer, forName: name)
  }
}
