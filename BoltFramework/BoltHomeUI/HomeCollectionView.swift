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

import Factory
import Overture

import BoltLocalizations
import BoltServices
import BoltUIFoundation

final class HomeCollectionView: UICollectionView {

  @Injected(\.libraryDocsetsManager)
  private var libraryDocsetsManager: LibraryDocsetsManager

  private let isForCollapsedSidebar: Bool

  init(isForCollapsedSidebar: Bool) {
    self.isForCollapsedSidebar = isForCollapsedSidebar

    self.headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, String> { cell, _, title in
      cell.contentConfiguration = update({ () -> UIListContentConfiguration in
        #if targetEnvironment(macCatalyst)
        return cell.defaultContentConfiguration()
        #else
        return isForCollapsedSidebar ? .prominentInsetGroupedHeader() : cell.defaultContentConfiguration()
        #endif
      }()) {
        $0.text = title
      }
      cell.accessories = [
        .outlineDisclosure(
          options: UICellAccessory.OutlineDisclosureOptions(style: .header)
        ),
      ]
    }

    self.cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, LibraryInstallationQueryResult> { cell, _, queryResult in
      cell.backgroundConfiguration = cell.defaultBackgroundConfiguration()
      cell.contentConfiguration = update(cell.defaultContentConfiguration()) {
        let standardDimension = UIListContentConfiguration.ImageProperties.standardDimension
        $0.imageProperties.reservedLayoutSize = CGSize(
          width: standardDimension,
          height: standardDimension
        )

        $0.prefersSideBySideTextAndSecondaryText = false
        $0.textToSecondaryTextVerticalPadding = 0

        switch queryResult {
        case let .docset(docset):
          $0.text = docset.displayName
          if !docset.installedAsLatestVersion {
            $0.secondaryText = docset.version
          }
          $0.image = docset.iconImageForList
        case let .broken(installation):
          $0.text = installation.name
          if installation.installedAsLatestVersion {
            $0.secondaryText = installation.version
          }
          $0.image = UIImage(systemName: "text.book.closed")
        }
      }

      var accessories: [UICellAccessory] = [
        .multiselect(displayed: .whenEditing),
      ]
      if isForCollapsedSidebar {
        accessories.append(.disclosureIndicator(displayed: .whenNotEditing))
      }
      cell.accessories = accessories
    }

    super.init(frame: .zero, collectionViewLayout: UICollectionViewLayout())

    collectionViewLayout = createLayout()

    allowsSelectionDuringEditing = true
    allowsMultipleSelectionDuringEditing = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  let headerRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, String>
  let cellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, LibraryInstallationQueryResult>

  private func createLayout() -> UICollectionViewLayout {
    let _isForCollapsedSidebar = isForCollapsedSidebar
    // swiftlint:disable:next trailing_closure
    return UICollectionViewCompositionalLayout(sectionProvider: { [weak self] _, layoutEnvironment in
      let section = NSCollectionLayoutSection.list(
        using: update(
          UICollectionLayoutListConfiguration(
            appearance: _isForCollapsedSidebar ? .insetGrouped : .sidebar
          )
        ) {
          $0.headerMode = .firstItemInSection
          $0.showsSeparators = false
          $0.trailingSwipeActionsConfigurationProvider = self?.createTrailingSwipeActionsConfigurationProvider()
        },
        layoutEnvironment: layoutEnvironment
      )
      #if targetEnvironment(macCatalyst)
      section.interGroupSpacing = 8
      #endif
      return section
    })
  }

  func itemContextMenuConfiguration(
    forIndexPath indexPath: IndexPath
  ) -> UIContextMenuConfiguration? {
    return UIContextMenuConfiguration(
      // swiftlint:disable:next trailing_closure
      actionProvider: { [weak self] _ in
        let getInfoButton = UIAction(
          title: BoltLocalizations.getInfo,
          image: UIImage(systemName: "info.circle")
        ) { [weak self] _ in
          guard let self = self else {
            return
          }
          onGetInfo(queryResult: docset(forIndexPath: indexPath))
        }
        let deleteButton = UIAction(
          title: UIKitLocalizations.delete,
          image: UIImage(systemName: "trash"),
          attributes: .destructive
        ) { [weak self] _ in
          guard let self = self, let queryResult = docset(forIndexPath: indexPath) else {
            return
          }
          onDeleteItems([queryResult])
        }
        return UIMenu(children: [getInfoButton, deleteButton])
      }
    )
  }

  func docset(forIndexPath indexPath: IndexPath) -> LibraryInstallationQueryResult? {
    //swiftlint:disable:next redundant_nil_coalescing
    return docsets(forIndexPaths: [indexPath]).first ?? nil
  }

  func docsets(forIndexPaths indexPaths: [IndexPath]) -> [LibraryInstallationQueryResult?] {
    guard let dataSource = (dataSource as? UICollectionViewDiffableDataSource<String, DocsetsListModel>) else {
      return []
    }
    return indexPaths.map {
      if
        let item = dataSource.itemIdentifier(for: $0),
        case let .docset(queryResult) = item
      {
        return queryResult
      }
      return nil
    }
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
          let handled = onGetInfo(queryResult: docset(forIndexPath: indexPath))
          completion(handled)
        }
      let deleteAction =
        UIContextualAction(
          style: .destructive,
          title: UIKitLocalizations.delete
        ) { [weak self] _, _, completion in
          guard let self = self, let queryResult = docset(forIndexPath: indexPath) else {
            return
          }
          onDeleteItems([queryResult])
          completion(true)
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

  func onDeleteItems(_ queryResults: [LibraryInstallationQueryResult]) {
    guard !queryResults.isEmpty else {
      return
    }

    let performUninstallDocsets = { [libraryDocsetsManager] in
      for queryResult in queryResults {
        try? libraryDocsetsManager.uninstallDocset(forInstallation: queryResult.installation)
      }
    }

    let alertMessage: String

    if queryResults.count == 1 {
      let queryResult = queryResults.first!

      let uninstallName = queryResult.displayName

      alertMessage = !uninstallName.isEmpty ?
        "Home-List-DeleteAlert-deleteDocsetMessageFormat".boltLocalized(uninstallName) :
        "Home-List-DeleteAlert-deleteDocsetMessage".boltLocalized
    } else {
      alertMessage = "Home-List-DeleteAlert-deleteDocsetMessageMultiple".boltLocalized(queryResults.count)
    }
    GlobalUI.presentAlertController(
      UIAlertController.alert(
        withTitle: "Home-List-DeleteAlert-deleteDocsetTitle".boltLocalized,
        message: alertMessage,
        confirmAction: (
          BoltLocalizations.confirm,
          UIAlertAction.Style.destructive,
          { performUninstallDocsets() }
        ),
        cancelAction: (UIKitLocalizations.cancel, nil)
      )
    )
  }

}
