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

final class HomeListCollectionViewItemCell: UICollectionViewListCell {

  private(set) var viewModel: HomeListItemViewModel?

  func configureCellContent(forViewModel viewModel: HomeListItemViewModel) {
    self.viewModel = viewModel
    contentConfiguration = update(defaultContentConfiguration()) {
      let standardDimension = UIListContentConfiguration.ImageProperties.standardDimension
      $0.imageProperties.reservedLayoutSize = CGSize(
        width: standardDimension,
        height: standardDimension
      )

      $0.prefersSideBySideTextAndSecondaryText = false
      $0.textToSecondaryTextVerticalPadding = 0

      $0.text = viewModel.title
      $0.secondaryText = viewModel.subTitle
      $0.image = viewModel.image
    }
  }

}

final class HomeListCollectionView: UICollectionView {

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

    self.cellRegistration = UICollectionView.CellRegistration<HomeListCollectionViewItemCell, HomeListItemViewModel> { cell, _, viewModel in
      cell.backgroundConfiguration = cell.defaultBackgroundConfiguration()
      cell.configureCellContent(forViewModel: viewModel)

      var accessories: [UICellAccessory] = [
        .reorder(displayed: .whenEditing),
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
  let cellRegistration: UICollectionView.CellRegistration<HomeListCollectionViewItemCell, HomeListItemViewModel>

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
          onGetInfo(viewModel: viewModel(forIndexPath: indexPath))
        }
        let deleteButton = UIAction(
          title: UIKitLocalizations.delete,
          image: UIImage(systemName: "trash"),
          attributes: .destructive
        ) { [weak self] _ in
          guard let self = self, let viewModel = viewModel(forIndexPath: indexPath) else {
            return
          }
          onDeleteItems([viewModel])
        }
        return UIMenu(children: [getInfoButton, deleteButton])
      }
    )
  }

  func viewModel(forIndexPath indexPath: IndexPath) -> HomeListItemViewModel? {
    //swiftlint:disable:next redundant_nil_coalescing
    return viewModel(forIndexPaths: [indexPath]).first ?? nil
  }

  func viewModel(forIndexPaths indexPaths: [IndexPath]) -> [HomeListItemViewModel?] {
    return indexPaths.map { indexPath in
      if let cell = cellForItem(at: indexPath) as? HomeListCollectionViewItemCell {
        return cell.viewModel
      }
      return nil
    }
  }

  func createTrailingSwipeActionsConfigurationProvider()
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
          let handled = onGetInfo(viewModel: viewModel(forIndexPath: indexPath))
          completion(handled)
        }
      let deleteAction =
        UIContextualAction(
          style: .destructive,
          title: UIKitLocalizations.delete
        ) { [weak self] _, _, completion in
          guard let self = self, let viewModel = viewModel(forIndexPath: indexPath) else {
            return
          }
          onDeleteItems([viewModel])
          completion(true)
        }

      return UISwipeActionsConfiguration(actions: [deleteAction, getInfoAction])
    }
  }

  // MARK: Actions

  @discardableResult
  private func onGetInfo(viewModel: HomeListItemViewModel?) -> Bool {
    if let docset = viewModel?.docset {
      BoltHomeNavigator.presentDocsetInfo(docset)
      return true
    }
    return false
  }

  func onDeleteItems(_ viewModels: [HomeListItemViewModel]) {
    guard !viewModels.isEmpty else {
      return
    }

    let alertMessage: String

    if viewModels.count == 1 {
      let viewModel = viewModels.first!

      let uninstallName = viewModel.title ?? ""

      alertMessage = !uninstallName.isEmpty ?
        "Home-List-DeleteAlert-deleteDocsetMessageFormat".boltLocalized(uninstallName) :
        "Home-List-DeleteAlert-deleteDocsetMessage".boltLocalized
    } else {
      alertMessage = "Home-List-DeleteAlert-deleteDocsetMessageMultiple".boltLocalized(viewModels.count)
    }
    GlobalUI.presentAlertController(
      UIAlertController.alert(
        withTitle: "Home-List-DeleteAlert-deleteDocsetTitle".boltLocalized,
        message: alertMessage,
        confirmAction: (
          BoltLocalizations.confirm,
          UIAlertAction.Style.destructive,
          {
            for viewModel in viewModels {
              viewModel.deleteItem()
            }
          }
        ),
        cancelAction: (UIKitLocalizations.cancel, nil)
      )
    )
  }

}
