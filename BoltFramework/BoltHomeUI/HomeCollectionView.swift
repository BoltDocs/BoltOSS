//
// Copyright (C) 2024 Bolt Contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit

import Overture

import BoltLocalizations
import BoltServices
import BoltUIFoundation

final class HomeCollectionView: UICollectionView {

  private let isForCollapsedSidebar: Bool

  init(isForCollapsedSidebar: Bool) {
    self.isForCollapsedSidebar = isForCollapsedSidebar

    self.headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, String> { cell, _, title in
      cell.contentConfiguration = update(cell.defaultContentConfiguration()) {
        $0.text = title
      }
      cell.accessories = [
        .outlineDisclosure(
          options: UICellAccessory.OutlineDisclosureOptions(style: .header)
        ),
      ]
    }

    self.cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, LibraryInstallationQueryResult> { cell, _, queryResult in
      #if targetEnvironment(macCatalyst)
      cell.backgroundConfiguration = update(cell.defaultBackgroundConfiguration()) {
        $0.cornerRadius = 6.0
        $0.backgroundInsets = NSDirectionalEdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0)
      }
      #endif
      cell.contentConfiguration = update(cell.defaultContentConfiguration()) {
        switch queryResult {
        case let .docset(docset):
          $0.text = docset.displayName
          $0.image = docset.iconImageForList
        case let .broken(installation):
          $0.text = installation.name
          $0.image = UIImage(systemName: "text.book.closed")
        }
        #if targetEnvironment(macCatalyst)
        $0.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 12, bottom: 14, trailing: 12)
        #else
        $0.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        #endif
      }
      if isForCollapsedSidebar {
        cell.accessories = [.disclosureIndicator()]
      }
    }

    super.init(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    self.collectionViewLayout = createLayout()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  let headerRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, String>
  let cellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, LibraryInstallationQueryResult>

  static func listAppearance(isForCollapsedSidebar: Bool) -> UICollectionLayoutListConfiguration.Appearance {
    if UIDevice.isiPad || !isForCollapsedSidebar {
      return .sidebar
    } else {
      return .insetGrouped
    }
  }

  private func createLayout() -> UICollectionViewLayout {
    return UICollectionViewCompositionalLayout { [weak self] _, layoutEnvironment in
      return update(
        NSCollectionLayoutSection.list(
          using: update(UICollectionLayoutListConfiguration(appearance: Self.listAppearance(isForCollapsedSidebar: self?.isForCollapsedSidebar ?? false))) {
            $0.headerMode = .firstItemInSection
            $0.showsSeparators = false
            $0.trailingSwipeActionsConfigurationProvider = self?.createTrailingSwipeActionsConfigurationProvider()
          },
          layoutEnvironment: layoutEnvironment
        )
      ) {
        $0.contentInsets = .init(top: 0, leading: 24, bottom: 0, trailing: 24)
      }
    }
  }

  func itemContextMenuConfiguration(
    forIndexPath indexPath: IndexPath
  ) -> UIContextMenuConfiguration? {
    // swiftlint:disable:next trailing_closure
    return UIContextMenuConfiguration(
      actionProvider: { [weak self] _ in
        let getInfoButton = UIAction(
          title: BoltLocalizations.getInfo,
          image: UIImage(systemName: "info.circle")
        ) { _ in
          guard let self = self else {
            return
          }
          self.onGetInfo(queryResult: self.docset(forIndexPath: indexPath))
        }
        let deleteButton = UIAction(
          title: UIKitLocalizations.delete,
          image: UIImage(systemName: "trash"),
          attributes: .destructive
        ) { [weak self] _ in
          guard let self = self else {
            return
          }
          onDeleteItem(queryResult: self.docset(forIndexPath: indexPath))
        }
        return UIMenu(children: [getInfoButton, deleteButton])
      }
    )
  }

  private func docset(forIndexPath indexPath: IndexPath) -> LibraryInstallationQueryResult? {
    if
      let item = (self.dataSource as? UICollectionViewDiffableDataSource<String, DocsetsListModel>)?.itemIdentifier(for: indexPath),
      case let .docset(queryResult) = item
    {
      return queryResult
    }
    return nil
  }

  private func createTrailingSwipeActionsConfigurationProvider()
    -> UICollectionLayoutListConfiguration.SwipeActionsConfigurationProvider?
  {
    return { [weak self] indexPath in
      let getInfoAction =
        UIContextualAction(
          style: .normal,
          title: BoltLocalizations.getInfo
        ) { [weak self] _, _, completion in
          guard let self = self else {
            return
          }
          let handled = self.onGetInfo(queryResult: self.docset(forIndexPath: indexPath))
          completion(handled)
        }
      let deleteAction =
        UIContextualAction(
          style: .destructive,
          title: UIKitLocalizations.delete
        ) { _, _, completion in
          guard let self = self else {
            return
          }
          self.onDeleteItem(queryResult: self.docset(forIndexPath: indexPath), completion)
        }

      return UISwipeActionsConfiguration(actions: [deleteAction, getInfoAction])
    }
  }

  // MARK: Actions

  @discardableResult
  private func onGetInfo(queryResult: LibraryInstallationQueryResult?) -> Bool {
    guard let queryResult = queryResult else {
      return false
    }
    if case let .docset(docset) = queryResult {
      BoltHomeNavigator.presentDocsetInfo(docset)
      return true
    } else {
      return false
    }
  }

  private func onDeleteItem(
    queryResult: LibraryInstallationQueryResult?,
    _ completion: ((Bool) -> Void)? = nil
  ) {
    guard let queryResult = queryResult else {
      completion?(false)
      return
    }

    let installationToUninstall = queryResult.installation
    let uninstallName = queryResult.displayName

    let alertMessage = !uninstallName.isEmpty ?
      "Home-List-DeleteAlert-deleteDocsetMessageFormat".boltLocalized(uninstallName) :
      "Home-List-DeleteAlert-deleteDocsetMessage".boltLocalized

    GlobalUI.presentAlertController(
      UIAlertController.alert(
        withTitle: "Home-List-DeleteAlert-deleteDocsetTitle".boltLocalized,
        message: alertMessage,
        confirmAction: (
          BoltLocalizations.confirm,
          UIAlertAction.Style.destructive,
          {
            try? LibraryDocsetsManager.shared.uninstallDocset(forInstallation: installationToUninstall)
            completion?(true)
          }
        ),
        cancelAction: (UIKitLocalizations.cancel, {
          completion?(false)
        })
      )
    )
  }

}
