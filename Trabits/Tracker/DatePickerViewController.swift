//
//  DatePickerViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 07/10/2023.
//

import UIKit

protocol DatePickerViewControllerDelegate: AnyObject {
  func dateSelectionHandler(date: Date)
}

class DatePickerViewController: UIViewController {
  private let datePicker = UIDatePicker()
  
  weak var delegate: DatePickerViewControllerDelegate?
  
  init(date: Date = Date()) {
    super.init(nibName: nil, bundle: nil)
    setupViews(date: date)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension DatePickerViewController {
  private func setupViews(date: Date) {
    view.backgroundColor = .background
    
    datePicker.date = Calendar.current.startOfDay(for: date)
    datePicker.preferredDatePickerStyle = .inline
    datePicker.datePickerMode = .date
    datePicker.calendar = Calendar.current

    datePicker.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(datePicker)
    datePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    datePicker.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .cancel,
      target: self,
      action: #selector(cancel)
    )
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .done,
      target: self,
      action: #selector(saveSelection)
    )
  }
  
  @objc private func cancel() {
    dismiss(animated: true)
  }
  
  @objc private func saveSelection() {
    delegate?.dateSelectionHandler(date: datePicker.date)
    dismiss(animated: true)
  }
}
