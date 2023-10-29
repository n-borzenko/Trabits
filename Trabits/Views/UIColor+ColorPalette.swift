//
//  UIColor+ColorPalette.swift
//  Trabits
//
//  Created by Natalia Borzenko on 15/09/2023.
//

import UIKit

extension UIColor {
  static let contrastColor = UIColor(named: "ContrastColor")!
  static let backgroundColor = UIColor(named: "BackgroundColor")!
  
  static let themeColor = UIColor.purple
}

enum ColorPalette {
  static let colors: [UIColor] = [
    .marshmallow,
    .quartz,
    .blush,
    .peach,
    .apricot,
    .caramel,
    .wheatfield,
    .meadow,
    .sage,
    .spearmint,
    .seaglass,
    .aqua,
    .lagoon,
    .wave,
    .azure,
    .skyline,
    .periwinkle,
    .lavender,
    .amethyst,
    .lilac
  ]
}
