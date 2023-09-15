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
}

enum ColorPalette: String, CaseIterable {
  case quartz = "QuartzColor"
  case blush = "BlushColor"
  case peach = "PeachColor"
  case apricot = "ApricotColor"
  case caramel = "CaramelColor"
  case wheatfield = "WheatfieldColor"
  case meadow = "MeadowColor"
  case sage = "SageColor"
  case mint = "MintColor"
  case seaglass = "SeaglassColor"
  case aqua = "AquaColor"
  case lagoon = "LagoonColor"
  case wave = "WaveColor"
  case azure = "AzureColor"
  case skyline = "SkylineColor"
  case periwinkle = "PeriwinkleColor"
  case lavender = "LavenderColor"
  case amethyst = "AmethystColor"
  case lilac = "LilacColor"
  case marshmallow = "MarshmallowColor"

  var color: UIColor {
    UIColor(named: self.rawValue) ?? .clear
  }
}
