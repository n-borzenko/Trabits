//
//  UpdateCategoryViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 06/09/2023.
//

import UIKit
import CoreData

struct EditableCategory {
  var title: String?
  var color: UIColor?
}

class UpdateCategoryViewController: UIViewController {
  private enum Section: Int {
    case title
    case color
  }

  private enum Item: Hashable {
    case header(String)
    case title
    case color
  }

  private typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

  private let context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext
  private var dataSource: DataSource!
  private var saveBarButton: UIBarButtonItem!

  private var category: Category?
  private var editableCategory = EditableCategory()
  private var categoriesCount: Int
  private var colors: [UIColor] = []
  private var isValid = false

  lazy private var collectionView: UICollectionView = {
    UICollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
  }()

  init(category: Category? = nil, categoriesCount: Int) {
    self.category = category
    self.categoriesCount = categoriesCount
    super.init(nibName: nil, bundle: nil)

    configureEditableCategory()
    setupViews()
    configureDataSource()
    applySnapshot()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension UpdateCategoryViewController {
  private func validate() {
    if let title = editableCategory.title, !title.isEmpty && editableCategory.color != nil {
      isValid = true
    } else {
      isValid = false
    }
    saveBarButton.isEnabled = isValid
    applySnapshot()
  }

  @objc private func cancel() {
    dismiss(animated: true)
  }

  @objc private func saveCategory() {
    guard isValid else { return }

    if let category = category {
      category.title = editableCategory.title
      category.color = editableCategory.color
    } else {
      let category = Category(context: context)
      category.title = editableCategory.title
      category.color = editableCategory.color
      category.orderPriority = categoriesCount
      category.habits = Set<Habit>() as NSSet
      do {
        try context.obtainPermanentIDs(for: [category])
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

  private func createLayout() -> UICollectionViewCompositionalLayout {
    var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
    configuration.headerMode = .firstItemInSection
    configuration.showsSeparators = false
    return UICollectionViewCompositionalLayout.list(using: configuration)
  }

  private func configureEditableCategory() {
    editableCategory.color = ColorPalette.allCases.first?.color
    guard let category = category else { return }
    editableCategory.title = category.title
    editableCategory.color = category.color
  }

  private func configureDataSource() {
    let textCellRegistration = UICollectionView.CellRegistration<TextFieldListCell, Item> { [unowned self] cell, indexPath, item in
      cell.textField.text = editableCategory.title
      cell.delegate = self
    }

    let colorPickerCellRegistration = UICollectionView.CellRegistration<ColorPickerListCell, Item> { [unowned self] cell, indexPath, item in
      cell.fill(selectedColor: editableCategory.color)
      cell.delegate = self
    }

    let headerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, indexPath, item in
      guard case let .header(text) = item else { return }
      var contentConfiguration = cell.defaultContentConfiguration()
      contentConfiguration.text = text
      cell.contentConfiguration = contentConfiguration
    }

    dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
      switch item {
      case .header(_):
        return collectionView.dequeueConfiguredReusableCell(using: headerCellRegistration, for: indexPath, item: item)
      case .title:
        return collectionView.dequeueConfiguredReusableCell(using: textCellRegistration, for: indexPath, item: item)
      case .color:
        return collectionView.dequeueConfiguredReusableCell(using: colorPickerCellRegistration, for: indexPath, item: item)
      }
    }
    collectionView.dataSource = dataSource
  }

  private func applySnapshot() {
    var snapshot = Snapshot()
    snapshot.appendSections([.title, .color])
    snapshot.appendItems([.header("Title"), .title], toSection: .title)
    snapshot.appendItems([.header("Color"), .color], toSection: .color)
    dataSource.apply(snapshot)
  }

  private func setupViews() {
    view.addPinnedSubview(collectionView)
    collectionView.allowsSelection = false
    collectionView.keyboardDismissMode = .interactiveWithAccessory

    saveBarButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveCategory))
    saveBarButton.isEnabled = false
    navigationItem.rightBarButtonItem = saveBarButton
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
    navigationItem.title = category != nil ? "Edit category" : "New category"
  }
}

extension UpdateCategoryViewController: TextFieldListCellDelegate {
  func textValueChanged(_ text: String?) {
    editableCategory.title = text
    validate()
  }
}

extension UpdateCategoryViewController: ColorPickerListCellDelegate {
  func colorValueChanged(_ color: UIColor?) {
    editableCategory.color = color
    validate()
  }
}
