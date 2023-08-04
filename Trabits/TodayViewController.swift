//
//  TodayViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 04/08/2023.
//

import UIKit

class TodayViewController: UIViewController {
  private var safeArea: UILayoutGuide!

  init() {
    super.init(nibName: nil, bundle: nil)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension TodayViewController {
  private func setupViews() {
    safeArea = view.safeAreaLayoutGuide

    view.backgroundColor = .white

    let label = UILabel()
    label.text = "Today"

    view.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 8).isActive = true
    label.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -8).isActive = true
    label.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 8).isActive = true
    label.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -8).isActive = true
  }
}
