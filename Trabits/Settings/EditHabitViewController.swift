//
//  EditHabitViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 03/08/2023.
//

import UIKit

class EditHabitViewController: UIViewController {
  private let context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext

  private var categoryLabel = UILabel()
  private var textField = UITextField()
  private var stackView = UIStackView()

  private var safeArea: UILayoutGuide!

  var category: Category? = nil
  var habit: Habit? = nil

  init(habit: Habit) {
    self.habit = habit
    super.init(nibName: nil, bundle: nil)

    setupViews()
    textField.text = habit.title
    categoryLabel.text = "Category: \(habit.category?.title ?? "Unknown")"
  }

  init(category: Category) {
    self.category = category
    super.init(nibName: nil, bundle: nil)

    setupViews()
    categoryLabel.text = "Category: \(category.title ?? "Unknown")"
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func cancel() {
    dismiss(animated: true)
  }

  @objc private func save() {
    if let habit = habit {
      habit.title = textField.text
    } else {
      let habit = Habit(context: context)
      habit.title = textField.text
      habit.category = category
    }

    if context.hasChanges {
      do {
        try context.save()
      } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
    dismiss(animated: true)
  }
}

extension EditHabitViewController {
  private func setupViews() {
    safeArea = view.safeAreaLayoutGuide

    view.backgroundColor = .white

    view.addSubview(stackView)
    stackView.axis = .vertical
    stackView.distribution = .fill
    stackView.spacing = 16
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor, constant: 0).isActive = true
    stackView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor, constant: 0).isActive = true
    stackView.widthAnchor.constraint(equalTo: safeArea.widthAnchor, multiplier: 0.7).isActive = true

    stackView.addArrangedSubview(categoryLabel)

    let titleLabel = UILabel()
    titleLabel.text = "Habit title"
    stackView.addArrangedSubview(titleLabel)

    textField.borderStyle = .roundedRect
    stackView.addArrangedSubview(textField)

    let cancelBarButton =  UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
    navigationItem.leftBarButtonItem = cancelBarButton
    let saveBarButton =  UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
    navigationItem.rightBarButtonItem = saveBarButton
  }
}
