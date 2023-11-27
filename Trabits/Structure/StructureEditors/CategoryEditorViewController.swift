//
//  CategoryEditorViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 15/11/2023.
//

import UIKit
import CoreData

struct CategoryDraft {
  var title: String?
  var color: UIColor?
}

class CategoryEditorViewController: UIViewController {
  private enum SectionIdentifier: Int {
    case title
    case color
  }

  private enum ItemIdentifier: Hashable {
    case header(String)
    case title
    case color
  }

  private typealias DataSource = UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>

  private let context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext
  private var dataSource: DataSource!
  private var saveBarButton: UIBarButtonItem!

  private var category: Category?
  private var categoryDraft = CategoryDraft()
  private var colors: [UIColor] = []
  private var isValid = false

  lazy private var collectionView: UICollectionView = {
    UICollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
  }()

  init(category: Category? = nil) {
    self.category = category
    super.init(nibName: nil, bundle: nil)

    configureCategoryDraft()
    setupViews()
    configureDataSource()
    applySnapshot()
    validate()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension CategoryEditorViewController {
  private func validate() {
    if let title = categoryDraft.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && categoryDraft.color != nil {
      isValid = true
    } else {
      isValid = false
    }
    saveBarButton.isEnabled = isValid
  }

  @objc private func cancel() {
    dismiss(animated: true)
  }

  @objc private func saveCategory() {
    guard isValid else { return }

    if let category = category {
      category.title = categoryDraft.title?.trimmingCharacters(in: .whitespacesAndNewlines)
      category.color = categoryDraft.color
    } else {
      var categoriesCount = 0
      do {
        let fetchRequest = Category.orderedCategoriesFetchRequest()
        fetchRequest.includesSubentities = false
        categoriesCount = try context.count(for: fetchRequest)
      } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
      
      let category = Category(context: context)
      category.title = categoryDraft.title?.trimmingCharacters(in: .whitespacesAndNewlines)
      category.color = categoryDraft.color
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

  private func configureCategoryDraft() {
    categoryDraft.color = PastelPalette.colors.first
    guard let category = category else { return }
    categoryDraft.title = category.title
    categoryDraft.color = category.color
  }

  private func configureDataSource() {
    let textCellRegistration = UICollectionView.CellRegistration<TextFieldListCell, ItemIdentifier> { [unowned self] cell, indexPath, item in
      cell.textField.text = categoryDraft.title
      cell.delegate = self
    }

    let colorPickerCellRegistration = UICollectionView.CellRegistration<ColorPickerListCell, ItemIdentifier> { [unowned self] cell, indexPath, item in
      cell.fill(selectedColor: categoryDraft.color)
      cell.delegate = self
    }

    let headerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, ItemIdentifier> { cell, indexPath, item in
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

extension CategoryEditorViewController: TextFieldListCellDelegate {
  func textValueChanged(_ text: String?) {
    categoryDraft.title = text
    validate()
  }
}

extension CategoryEditorViewController: ColorPickerListCellDelegate {
  func colorValueChanged(_ color: UIColor?) {
    categoryDraft.color = color
    validate()
  }
}
