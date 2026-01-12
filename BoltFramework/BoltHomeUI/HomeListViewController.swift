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
import BoltRxSwift
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
      $0.textToSecondaryTextVerticalPadding = 2

      #if targetEnvironment(macCatalyst)
      $0.textProperties.numberOfLines = 1
      #else
      $0.textProperties.numberOfLines = 2
      #endif

      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineHeightMultiple = 1
      paragraphStyle.lineBreakMode = .byTruncatingTail

      let attributedTitle = NSAttributedString(
        string: viewModel.title ?? "",
        attributes: [
          .font: UIFont.systemFont(ofSize: 16),
          .paragraphStyle: paragraphStyle,
        ]
      )

      $0.attributedText = attributedTitle
      $0.secondaryText = viewModel.subTitle
      $0.image = viewModel.image?.image
    }
  }

}

final class HomeListViewController: UIViewController, UICollectionViewDelegate, HasDisposeBag {

  private let isForCollapsedSidebar: Bool

  private lazy var collectionView: UICollectionView = {
    return update(UICollectionView(frame: .zero, collectionViewLayout: createLayout())) {
      $0.delegate = self
    }
  }()

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

    super.init(nibName: nil, bundle: nil)

    collectionView.allowsSelectionDuringEditing = true
    collectionView.allowsMultipleSelectionDuringEditing = true

    collectionView.dataSource = dataSource
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  private let headerRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, String>
  private let cellRegistration: UICollectionView.CellRegistration<HomeListCollectionViewItemCell, HomeListItemViewModel>

  private(set) lazy var dataSource: UICollectionViewDiffableDataSource<HomeListSection, DocsetsListModel> = createDataSource()

  private(set) lazy var isEditingObserver: AnyObserver<Bool> = { isEditingSubject.asObserver() }()
  private var isEditingSubject = PublishSubject<Bool>()

  var selectedIndexPathsForEditing: [IndexPath] { selectedIndexPathsForEditingRelay.value }
  private(set) lazy var selectedIndexPathsForEditingDriver: Driver<[IndexPath]> = { selectedIndexPathsForEditingRelay.asDriver() }()
  private var selectedIndexPathsForEditingRelay = BehaviorRelay<[IndexPath]>(value: [])

  private(set) lazy var itemSelectedSignal: Signal<IndexPath> = { itemSelectedRelay.asSignal() }()
  private var itemSelectedRelay = PublishRelay<IndexPath>()

  func selectItem(at indexPath: IndexPath?, animated: Bool, scrollPosition: UICollectionView.ScrollPosition) {
    collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)
  }

  func deleteItems(atIndexPaths indexPaths: [IndexPath]) {
    let viewModels = viewModel(forIndexPaths: indexPaths).compactMap { $0 }
    onDeleteItems(viewModels)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    with(collectionView) {
      view.addSubview($0)
      $0.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }
    }

    isEditingSubject
      .bind(to: collectionView.rx.isEditing)
      .disposed(by: disposeBag)

    collectionView.rx.itemSelected
      .subscribe(with: self) { owner, indexPath in
        let collectionView = owner.collectionView
        if !collectionView.isEditing {
          collectionView.deselectItem(at: indexPath, animated: false)
          owner.itemSelectedRelay.accept(indexPath)
        }
      }
      .disposed(by: disposeBag)

    Observable.merge(
      isEditingSubject.mapToVoid(),
      collectionView.rx.itemSelected.mapToVoid(),
      collectionView.rx.itemDeselected.mapToVoid()
    )
    .subscribe(with: self) { owner, _ in
      let collectionView = owner.collectionView
      if collectionView.isEditing {
        owner.selectedIndexPathsForEditingRelay.accept(collectionView.indexPathsForSelectedItems ?? [])
      }
    }
    .disposed(by: disposeBag)
  }

  private func createDataSource() -> UICollectionViewDiffableDataSource<HomeListSection, DocsetsListModel> {
    return UICollectionViewDiffableDataSource(
      collectionView: collectionView
    ) { [weak self] collectionView, indexPath, docsetsListModel in
      guard let self = self else {
        return nil
      }
      switch docsetsListModel {
      case let .header(section):
        return headerRegistration.cellProvider(collectionView, indexPath, section.localized)
      case let .docset(viewModel):
        return cellRegistration.cellProvider(collectionView, indexPath, viewModel)
      }
    }
  }

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

  func viewModel(forIndexPath indexPath: IndexPath) -> HomeListItemViewModel? {
    //swiftlint:disable:next redundant_nil_coalescing
    return viewModel(forIndexPaths: [indexPath]).first ?? nil
  }

  func viewModel(forIndexPaths indexPaths: [IndexPath]) -> [HomeListItemViewModel?] {
    return indexPaths.map { indexPath in
      if let cell = collectionView.cellForItem(at: indexPath) as? HomeListCollectionViewItemCell {
        return cell.viewModel
      }
      return nil
    }
  }

  private func createTrailingSwipeActionsConfigurationProvider()
    -> UICollectionLayoutListConfiguration.SwipeActionsConfigurationProvider?
  {
    return { [weak self] indexPath in
      guard let self = self, viewModel(forIndexPath: indexPath) != nil else {
        return nil
      }
      let getInfoAction =
        UIContextualAction(
          style: .normal,
          title: BoltLocalizations.getInfo
        ) { [weak self] _, _, completion in
          guard let self = self else {
            completion(false)
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
          guard let self = self else  {
            completion(false)
            return
          }
          deleteItems(atIndexPaths: [indexPath])
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

  private func onDeleteItems(_ viewModels: [HomeListItemViewModel]) {
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

  // MARK: - UICollectionViewDelegate

  func collectionView(
    _ collectionView: UICollectionView,
    contextMenuConfigurationForItemAt indexPath: IndexPath,
    point: CGPoint
  ) -> UIContextMenuConfiguration? {
    guard viewModel(forIndexPath: indexPath) != nil else {
      return nil
    }
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
          guard let self = self else {
            return
          }
          deleteItems(atIndexPaths: [indexPath])
        }
        return UIMenu(children: [getInfoButton, deleteButton])
      }
    )
  }

}
