//
//  DatePickerViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 07/10/2023.
//

import UIKit
import SwiftUI

struct DatePickerView: UIViewControllerRepresentable {
  typealias UIViewControllerType = UINavigationController
  
  var selectedDate: Date
  weak var delegate: DatePickerViewControllerDelegate?
  
  func makeUIViewController(context: Context) -> UINavigationController {
    let datePickerController = DatePickerViewController(date: selectedDate)
    datePickerController.delegate = delegate
    return UINavigationController(rootViewController: datePickerController)
  }
  
  func updateUIViewController(_ uiViewController: UINavigationController, context: Context) { }
}

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
    view.backgroundColor = .tertiarySystemBackground
    
    datePicker.date = Calendar.current.startOfDay(for: date)
    datePicker.preferredDatePickerStyle = .inline
    datePicker.datePickerMode = .date
    datePicker.calendar = Calendar.current
    if #unavailable(iOS 17) {
      // gray neutral color is set for the dark appearance
      // as white was not supported before by the native date picker
      datePicker.tintColor = .datePickerTint
    }

    datePicker.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(datePicker)
    datePicker.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    datePicker.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
    
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
