//
//  TrackerListViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 01/10/2023.
//

import UIKit

class TrackerListViewController: UIViewController {
  private var date: Date
  
  init(date: Date) {
    self.date = date
    super.init(nibName: nil, bundle: nil)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension TrackerListViewController {
  private func setupViews() {
    view.backgroundColor = .yellow
    view.layer.cornerRadius = 44
    
    let scrollView = UIScrollView()
    view.addPinnedSubview(scrollView)
    
    let label = UILabel()
    label.text = date.formatted()
    scrollView.addPinnedSubview(label)
    label.heightAnchor.constraint(equalToConstant: 1000).isActive = true
  }
}
