//
//  CategoryDetailViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 24/07/2023.
//

import UIKit
import CoreData

class CategoryDetailViewController: UIViewController {
  private let context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext

  private var category: Category
  private var fetchResultsController: NSFetchedResultsController<Habit>!
  private var dataSource: CategoryDetailDataSource!
  private let tableView = UITableView()

  init(category: Category) {
    self.category = category
    super.init(nibName: nil, bundle: nil)
    setupViews()
    configureDataSource()
    applySnapshot()
    configureFetchedResultsController()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func addHabit() {
    let addHabitViewController = EditHabitViewController(category: category)
    let navigationViewController = UINavigationController(rootViewController: addHabitViewController)
    present(navigationViewController, animated: true)
  }
}

enum CategoryDetailTableViewSection: String {
  case category
  case habits
}

enum CategoryDetailTableViewItem: Hashable {
  case category(Category)
  case habit(NSManagedObjectID)
}

class CategoryDetailDataSource: UITableViewDiffableDataSource<CategoryDetailTableViewSection, CategoryDetailTableViewItem> {
//  var delegate: CategoryDataSourceDelegate?

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    indexPath.section != 0
  }

  override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    indexPath.section != 0
  }

  override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//    delegate?.moveCategory(at: sourceIndexPath, to: destinationIndexPath)
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
//      delegate?.deleteCategory(at: indexPath)
    }
  }
}

extension CategoryDetailViewController: NSFetchedResultsControllerDelegate {
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
    let snapshot = snapshot as NSDiffableDataSourceSnapshot<AnyHashable, NSManagedObjectID>

    var newSnapshot = dataSource.snapshot()
    newSnapshot.deleteItems(newSnapshot.itemIdentifiers(inSection: .habits))

    let items = snapshot.itemIdentifiers.map { CategoryDetailTableViewItem.habit($0) }
    newSnapshot.appendItems(items, toSection: .habits)
    dataSource.apply(newSnapshot, animatingDifferences: false)
  }
}

extension CategoryDetailViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard section > 0 else {
      return nil
    }

    let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: CategoryDetailHabitsHeader.reuseIdentifier)
    if let headerView = headerView as? CategoryDetailHabitsHeader {
      headerView.fill(with: "Habits", category: category)
    }
    return headerView
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    section == 0 ? 0 : UITableView.automaticDimension
  }

  func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
    section == 0 ? 0 : 40
  }
}

extension CategoryDetailViewController {
  func configureDataSource() {
    dataSource = CategoryDetailDataSource(tableView: tableView) { [unowned self] (tableView: UITableView, indexPath: IndexPath, id: CategoryDetailTableViewItem) -> UITableViewCell? in

      if case let CategoryDetailTableViewItem.habit(objectID) = id {
        let cell = tableView.dequeueReusableCell(withIdentifier: CategoryDetailHabitCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? CategoryDetailHabitCell, let habit = self.context.object(with: objectID) as? Habit {
          cell.fill(with: habit)
        }
        return cell
      }

      if case let CategoryDetailTableViewItem.category(category) = id {
        let cell = tableView.dequeueReusableCell(withIdentifier: CategoryDetailCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? CategoryDetailCell {
          cell.fill(with: category)
          cell.delegate = self
        }
        return cell
      }

      return nil
    }
  }

  func applySnapshot() {
    var snapshot = NSDiffableDataSourceSnapshot<CategoryDetailTableViewSection, CategoryDetailTableViewItem>()
    snapshot.appendSections([.category])
    snapshot.appendItems([.category(self.category)], toSection: .category)

    snapshot.appendSections([.habits])
    dataSource.apply(snapshot)
  }

  func configureFetchedResultsController() {
    let fetchRequest = Habit.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
    fetchRequest.predicate = NSPredicate(format: "category == %@", category)
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

extension CategoryDetailViewController: CategoryDetailCellDelegate {
  func editCategory() {
    let editCategoryViewController = EditCategoryViewController(category: category)
    let navigationViewController = UINavigationController(rootViewController: editCategoryViewController)
    present(navigationViewController, animated: true)
  }
}

extension CategoryDetailViewController {
  private func setupViews() {
    view.addSubview(tableView)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
    tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
    tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
    tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
    tableView.separatorStyle = .none

    tableView.register(CategoryDetailCell.self, forCellReuseIdentifier: CategoryDetailCell.reuseIdentifier)
    tableView.register(CategoryDetailHabitCell.self, forCellReuseIdentifier: CategoryDetailHabitCell.reuseIdentifier)
    tableView.register(CategoryDetailHabitsHeader.self, forHeaderFooterViewReuseIdentifier: CategoryDetailHabitsHeader.reuseIdentifier)
    tableView.delegate = self

    navigationItem.largeTitleDisplayMode = .never
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0
    }

    let addHabitBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addHabit))
    navigationItem.rightBarButtonItem = addHabitBarButton

    navigationController?.isToolbarHidden = true
  }
}
