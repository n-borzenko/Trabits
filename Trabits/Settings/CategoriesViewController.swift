//
//  CategoriesViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 19/06/2023.
//

import UIKit
import CoreData

enum CategoriesTableViewSection: String {
  case main
}

class CategoriesViewController: UIViewController {
  private let context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext

  private var fetchResultsController: NSFetchedResultsController<Category>!
  private var dataSource: CategoryDataSource!
  private var tableView = UITableView()
  private var editTableBarButton = UIBarButtonItem(title: "Edit")

  init() {
    super.init(nibName: nil, bundle: nil)
    setupViews()
    configureDataSource()
    configureFetchedResultsController()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func editTable() {
    tableView.isEditing.toggle()
    editTableBarButton.title = tableView.isEditing ? "Done" : "Edit"
  }
  
  @objc private func addCategory() {
    let addCategoryViewController = EditCategoryViewController(
      categoriesCount: fetchResultsController.fetchedObjects?.count ?? 0
    )
    let navigationViewController = UINavigationController(rootViewController: addCategoryViewController)
    present(navigationViewController, animated: true)
  }
}

extension CategoriesViewController: NSFetchedResultsControllerDelegate {
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
    let snapshot = snapshot as NSDiffableDataSourceSnapshot<CategoriesTableViewSection, NSManagedObjectID>
    dataSource.apply(snapshot, animatingDifferences: false)
    tableView.backgroundView?.isHidden = dataSource.snapshot().numberOfItems > 0
  }
}

protocol CategoryDataSourceDelegate {
  func deleteCategory(at indexPath: IndexPath)
  func moveCategory(at sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
}

extension CategoriesViewController: CategoryDataSourceDelegate {
  func deleteCategory(at indexPath: IndexPath) {
    let category = fetchResultsController.object(at: indexPath)
    let itemsCount = (fetchResultsController.sections?[0].numberOfObjects ?? 0)
    for i in (indexPath.row + 1)..<itemsCount {
      let item = fetchResultsController.object(at: IndexPath(row: i, section: 0))
      item.orderPriority -= 1
    }

    context.delete(category)

    do {
      try context.save()
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
  }

  func moveCategory(at sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    let category = fetchResultsController.object(at: sourceIndexPath)
    category.orderPriority = destinationIndexPath.row

    if sourceIndexPath.row < destinationIndexPath.row {
      for i in (sourceIndexPath.row + 1)...(destinationIndexPath.row) {
        let item = fetchResultsController.object(at: IndexPath(row: i, section: 0))
        item.orderPriority -= 1
      }
    } else {
      for i in (destinationIndexPath.row)..<(sourceIndexPath.row) {
        let item = fetchResultsController.object(at: IndexPath(row: i, section: 0))
        item.orderPriority += 1
      }
    }

    Task {
      do {
        try context.save()
      } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }
}

class CategoryDataSource: UITableViewDiffableDataSource<CategoriesTableViewSection, NSManagedObjectID> {
  var delegate: CategoryDataSourceDelegate?

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    true
  }

  override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    true
  }

  override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    delegate?.moveCategory(at: sourceIndexPath, to: destinationIndexPath)
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      delegate?.deleteCategory(at: indexPath)
    }
  }
}

extension CategoriesViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let category = fetchResultsController.object(at: indexPath)
    let detailViewController = CategoryDetailViewController(category: category)
    navigationController?.pushViewController(detailViewController, animated: true)
    tableView.deselectRow(at: indexPath, animated: false)
  }
}

extension CategoriesViewController {
  func configureDataSource() {
    dataSource = CategoryDataSource(tableView: tableView) { [unowned self] (tableView: UITableView, indexPath: IndexPath, id: NSManagedObjectID) -> UITableViewCell? in
      let cell = tableView.dequeueReusableCell(withIdentifier: CategoryCell.reuseIdentifier, for: indexPath)
      if let cell = cell as? CategoryCell, let category = self.context.object(with: id) as? Category  {
        cell.fill(with: category)
      }
      return cell
    }

    dataSource.delegate = self
  }

  func configureFetchedResultsController() {
    let fetchRequest = Category.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
    fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    fetchResultsController.delegate = self

    do {
      try fetchResultsController.performFetch()
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
  }
}

extension CategoriesViewController {
  private func setupViews() {
    view.addSubview(tableView)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
    tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
    tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
    tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
    tableView.separatorStyle = .none

    tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.reuseIdentifier)
    tableView.delegate = self
    tableView.allowsSelection = true
    tableView.allowsMultipleSelection = false

    let emptyView = EmptyStateView()
    tableView.backgroundView = emptyView

    navigationItem.title = "Categories"
    navigationItem.largeTitleDisplayMode = .always

    editTableBarButton.target = self
    editTableBarButton.action = #selector(editTable)
    navigationItem.leftBarButtonItem = editTableBarButton

    let addCategoryBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCategory))
    navigationItem.rightBarButtonItem = addCategoryBarButton
  }
}
