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

  private let isCompact: Bool

  init(isCompact: Bool) {
    self.isCompact = isCompact

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
      if isCompact {
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

  static func listAppearance(isCompact: Bool) -> UICollectionLayoutListConfiguration.Appearance {
    if UIDevice.isiPad || !isCompact {
      return .sidebar
    } else {
      return .insetGrouped
    }
  }

  private func createLayout() -> UICollectionViewLayout {
    return UICollectionViewCompositionalLayout { [weak self] _, layoutEnvironment in
      return update(
        NSCollectionLayoutSection.list(
          using: update(UICollectionLayoutListConfiguration(appearance: Self.listAppearance(isCompact: self?.isCompact ?? false))) {
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

  private func createTrailingSwipeActionsConfigurationProvider()
    -> UICollectionLayoutListConfiguration.SwipeActionsConfigurationProvider?
  {
    return { [weak self] indexPath in
      let itemAccessor = { () -> LibraryInstallationQueryResult? in
        if
          let self = self,
          let item = (self.dataSource as? UICollectionViewDiffableDataSource<String, DocsetsListModel>)?
            .itemIdentifier(for: indexPath),
          case let .docset(queryResult) = item
        {
          return queryResult
        }
        return nil
      }

      let info = update(
        UIContextualAction(
          style: .normal,
          title: "Info"
        ) { _, _, completion in
          guard let queryResult = itemAccessor() else {
            completion(false)
            return
          }
          if case let .docset(docset) = queryResult {
            BoltHomeNavigator.presentDocsetInfo(docset)
            completion(true)
          } else {
            completion(false)
          }
        }
      ) {
        $0.image = UIImage(systemName: "info.circle")
      }

      let delete = update(
        UIContextualAction(
          style: .destructive,
          title: "Delete"
        ) { _, _, completion in
          guard let queryResult = itemAccessor() else {
            completion(false)
            return
          }

          let installationToUninstall = queryResult.installation
          let uninstallName = queryResult.displayName

          GlobalUI.presentAlertController(
            UIAlertController.controllerInAlertStyle(
              withTitle: "Uninstall",
              message: "Do you really want to uninstall \(uninstallName)",
              confirmAction: ("Confirm", UIAlertAction.Style.destructive, {
                try? LibraryDocsetsManager.shared.uninstallDocset(forInstallation: installationToUninstall)
                completion(true)
              }),
              cancelAction: (UIKitLocalization.cancel, {
                completion(false)
              })
            )
          )
        }
      ) {
        $0.image = UIImage(systemName: "trash")
      }

      return UISwipeActionsConfiguration(actions: [delete, info])
    }
  }

}
