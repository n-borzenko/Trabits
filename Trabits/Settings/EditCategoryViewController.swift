//
//  NewCategoryViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 23/06/2023.
//

import UIKit

class EditCategoryViewController: UIViewController {
  private let context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext

  private var textField = UITextField()
  private var colorPicker = UIColorWell()
  private var stackView = UIStackView()

  private var safeArea: UILayoutGuide!

  var category: Category?
  var categoriesCount: Int

  init(categoriesCount: Int = 0, category: Category? = nil) {
    self.category = category
    self.categoriesCount = categoriesCount
    super.init(nibName: nil, bundle: nil)

    setupViews()

    if let category = category {
      textField.text = category.title
      colorPicker.selectedColor = category.color
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func cancel() {
    dismiss(animated: true)
  }

  @objc private func save() {
    if let category = category {
      category.title = textField.text
      category.color = colorPicker.selectedColor
    } else {
      let category = Category(context: context)
      category.title = textField.text
      category.color = colorPicker.selectedColor
      category.orderPriority = categoriesCount
      category.habits = Set<Habit>() as NSSet
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

extension EditCategoryViewController {
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

    let titleLabel = UILabel()
    titleLabel.text = "Title"
    titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
    titleLabel.adjustsFontForContentSizeCategory = true
    stackView.addArrangedSubview(titleLabel)

    stackView.addArrangedSubview(textField)
    textField.borderStyle = .roundedRect
    textField.font = UIFont.preferredFont(forTextStyle: .body)
    textField.adjustsFontForContentSizeCategory = true

    let colorStackView = UIStackView()
    colorStackView.axis = .horizontal
    colorStackView.distribution = .equalSpacing
    colorStackView.alignment = .center
    stackView.addArrangedSubview(colorStackView)

    let colorLabel = UILabel()
    colorLabel.text = "Color"
    colorLabel.font = UIFont.preferredFont(forTextStyle: .body)
    colorLabel.adjustsFontForContentSizeCategory = true
    colorStackView.addArrangedSubview(colorLabel)
    colorLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    colorStackView.addArrangedSubview(colorPicker)

    let cancelBarButton =  UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
    navigationItem.leftBarButtonItem = cancelBarButton
    let saveBarButton =  UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
    navigationItem.rightBarButtonItem = saveBarButton
  }
}
