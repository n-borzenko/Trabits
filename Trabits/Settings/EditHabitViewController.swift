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

  // edit existing habit
  init(habit: Habit) {
    self.habit = habit
    super.init(nibName: nil, bundle: nil)

    setupViews()
    textField.text = habit.title
    categoryLabel.text = "Category: \(habit.category?.title ?? "Unknown")"
  }

  // add new habit
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
      habit.orderPriority = Int(category?.habits?.count ?? 0)
      habit.category = category
      do {
        try context.obtainPermanentIDs(for: [habit])
      } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
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
    categoryLabel.font = UIFont.preferredFont(forTextStyle: .body)
    categoryLabel.adjustsFontForContentSizeCategory = true

    let titleLabel = UILabel()
    titleLabel.text = "Habit title"
    titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
    titleLabel.adjustsFontForContentSizeCategory = true
    stackView.addArrangedSubview(titleLabel)

    stackView.addArrangedSubview(textField)
    textField.borderStyle = .roundedRect
    textField.font = UIFont.preferredFont(forTextStyle: .body)
    textField.adjustsFontForContentSizeCategory = true

    let cancelBarButton =  UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
    navigationItem.leftBarButtonItem = cancelBarButton
    let saveBarButton =  UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
    navigationItem.rightBarButtonItem = saveBarButton
  }
}
