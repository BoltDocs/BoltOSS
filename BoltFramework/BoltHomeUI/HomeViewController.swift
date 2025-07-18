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
import IssueReporting
import Overture
import RxCocoa
import RxCombine
import RxSwift
import SnapKit

import BoltLocalizations
import BoltModuleExports
import BoltServices
import BoltUIFoundation

enum DocsetsListModel: Hashable {
  case header(String)
  case docset(LibraryInstallationQueryResult)
}

public final class HomeViewController: BaseViewController, SearchBarProvider {

  @Injected(\.analyticsService)
  private var analyticsService: AnalyticsService?

  @Injected(\.libraryDocsetsManager)
  private var libraryDocsetsManager: LibraryDocsetsManager

  struct SectionNames {
    static let docsets = "Docsets"
    static let favorites = "Favorites"
    static let history = "History"
  }

  private let sceneState: SceneState
  private let isForCollapsedSidebar: Bool

  private let isEditingRelay = BehaviorRelay<Bool>(value: false)
  private lazy var isEditingObservable = {
    return isEditingRelay.asObservable().distinctUntilChanged()
  }()

  private lazy var toolbarTrashItem: UIBarButtonItem = {
    return update(UIBarButtonItem()) {
      $0.primaryAction = UIAction(
        image: UIImage(systemName: "trash")
      ) { [weak self] _ in
        guard let self = self, let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
          return
        }
        let queryResults = collectionView.docsets(forIndexPaths: selectedIndexPaths).compactMap { $0 }
        collectionView.onDeleteItems(queryResults)
      }
    }
  }()

  public init(sceneState: SceneState, isForCollapsedSidebar: Bool) {
    self.sceneState = sceneState
    self.isForCollapsedSidebar = isForCollapsedSidebar
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  private lazy var collectionView: HomeCollectionView = {
    return update(HomeCollectionView(isForCollapsedSidebar: isForCollapsedSidebar)) {
      $0.delegate = self
    }
  }()

  private func setupToolbar() {
    navigationController?.setToolbarHidden(false, animated: true)

    let rightBarButtonItems = isEditingObservable.map { isEditing -> [UIBarButtonItem] in
      isEditing ? [
        update(
          UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak self] _ in
              self?.isEditingRelay.accept(false)
            }
          )
        ) {
          $0.tintColor = UIColor.tintColor
        },
      ] : [
        update(
          UIBarButtonItem(
            title: nil,
            image: UIImage(systemName: "ellipsis.circle"),
            primaryAction: nil,
            menu: UIMenu(
              title: "",
              children: [
                UIAction(
                  title: "Select",
                  image: UIImage(systemName: "checkmark.circle")
                ) { [weak self] _ in
                  self?.isEditingRelay.accept(true)
                },
              ]
            )
          )
        ) {
          $0.tintColor = UIColor.tintColor
        },
      ]
    }

    rightBarButtonItems
      .bind(to: navigationItem.rx.rightBarButtonItems)
      .disposed(by: disposeBag)

    Observable.merge(
      isEditingRelay.mapToVoid(),
      collectionView.rx.itemSelected.mapToVoid(),
      collectionView.rx.itemDeselected.mapToVoid()
    )
    .map { [collectionView] _ -> Bool in
      guard let selectedItems = collectionView.indexPathsForSelectedItems else {
        return false
      }
      return !selectedItems.isEmpty
    }
    .bind(to: toolbarTrashItem.rx.isEnabled)
    .disposed(by: disposeBag)

    let toolbarItems = isEditingRelay.map { [toolbarTrashItem] isEditing -> [UIBarButtonItem] in
      var items = isEditing ? [
        toolbarTrashItem,
        .flexibleSpace(),
      ] : [
        update(UIBarButtonItem()) {
          $0.primaryAction = UIAction(
            image: UIImage(systemName: "gear")
          ) { [weak self] _ in
            self?.sceneState.dispatch(action: .onHomeViewTapMenuItemPreferences)
          }
        },
        .flexibleSpace(),
        update(UIBarButtonItem()) {
          $0.primaryAction = UIAction(
            title: "Downloads"
          ) { [weak self] _ in
            self?.sceneState.dispatch(action: .onHomeViewTapMenuItemDownloads)
          }
        },
        .flexibleSpace(),
      ]
      items.append(
        update(UIBarButtonItem()) {
          $0.primaryAction = UIAction(
            image: UIImage(systemName: "plus")
          ) { [weak self] _ in
            guard let self = self else {
              return
            }
            isEditingRelay.accept(false)
            sceneState.dispatch(action: .onHomeViewTapMenuItemLibrary)
          }
        }
      )
      return items
    }

    toolbarItems
      .bind(to: rx.toolbarItems)
      .disposed(by: disposeBag)
  }

  private func setupCollectionView() {
    with(collectionView) {
      view.addSubview($0)
      $0.snp.makeConstraints { make in
        make.top.equalToSuperview()
        make.leading.equalTo(view.safeAreaLayoutGuide)
        make.trailing.equalTo(view.safeAreaLayoutGuide)
        make.bottom.equalToSuperview()
      }
    }
    isEditingRelay
      .bind(to: collectionView.rx.isEditing)
      .disposed(by: disposeBag)
  }

  private func setupSearchController() {
    let searchController = update(UISearchController()) {
      $0.showsSearchResultsController = false
      $0.obscuresBackgroundDuringPresentation = false
      $0.automaticallyShowsScopeBar = false
    }

    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false

    searchBar.autocapitalizationType = .none
    searchBar.placeholder = "Filter"
  }

  var docsets = BehaviorRelay<[LibraryInstallationQueryResult]>(value: [])

  var dataSource: UICollectionViewDiffableDataSource<String, DocsetsListModel>!

  override public func viewDidLoad() {
    super.viewDidLoad()

    title = "Library"

    view.backgroundColor = .secondarySystemBackground

    updateNavBarAppearance()

    setupToolbar()
    setupSearchController()
    setupCollectionView()

    dataSource = UICollectionViewDiffableDataSource(
      collectionView: collectionView
    ) { collectionView, indexPath, DocsetsListModel in
      guard let collectionView = collectionView as? HomeCollectionView else {
        reportIssue("Unexpected collectionView cell type")
        return nil
      }
      switch DocsetsListModel {
      case .header(let title):
        return collectionView.headerRegistration.cellProvider(collectionView, indexPath, title)
      case .docset(let docset):
        return collectionView.cellRegistration.cellProvider(collectionView, indexPath, docset)
      }
    }

    dataSource.reorderingHandlers.canReorderItem = { _ in return true }

    dataSource.reorderingHandlers.didReorder = { [libraryDocsetsManager] transaction in
      guard let docsetSectionTransaction = transaction
        .sectionTransactions
        .first(where: { $0.sectionIdentifier == SectionNames.docsets })
      else {
        return
      }
      let snapshot = docsetSectionTransaction.finalSnapshot
      let allItems: [DocsetsListModel] = {
        guard let rootItem = snapshot.rootItems.first else {
          return []
        }
        return docsetSectionTransaction.finalSnapshot.items.filter {
          snapshot.parent(of: $0) == rootItem
        }
      }()
      let records = allItems
        .compactMap { listModel -> LibraryRecord? in
          switch listModel {
          case let .docset(queryResult):
            return queryResult.record
          case .header:
            reportIssue("docset reordering: unexpected listModel type")
            return nil
          }
        }
      do {
        try libraryDocsetsManager.updateInstalledDocsetsOrder(records)
      } catch {
        Self.logger.error("docset reordering: updateInstalledDocsetsOrder failed with error: \(error)")
      }
    }

    var dataSourceSnapshot = NSDiffableDataSourceSnapshot<String, DocsetsListModel>()
    dataSourceSnapshot.appendSections([
      SectionNames.docsets,
      SectionNames.favorites,
      SectionNames.history,
    ])

    // TODO: build favorites and history section
    dataSource.apply(dataSourceSnapshot)

    libraryDocsetsManager.installedDocsetsPublisher
      .asInfallible()
      .bind(to: docsets)
      .disposed(by: disposeBag)

    Driver.combineLatest(
      docsets.asDriver(),
      searchBar.rx.text.asDriver()
    )
    .map { docsets, query -> [LibraryInstallationQueryResult] in
      if let query = query, !query.isEmpty {
        return docsets.filter { queryResult in
          return queryResult.displayName.lowercased().contains(query)
        }
      }
      return docsets
    }
    .map { docsets in
      update(NSDiffableDataSourceSectionSnapshot<DocsetsListModel>()) {
        let headerDocsetsListModel = DocsetsListModel.header("Docsets")
        $0.append([headerDocsetsListModel])

        let symbolDocsetsListModelArray = docsets.map { DocsetsListModel.docset($0) }
        $0.append(symbolDocsetsListModelArray, to: headerDocsetsListModel)

        $0.expand([headerDocsetsListModel])
      }
    }
    .drive { [dataSource] snapshot in
      dataSource?.apply(snapshot, to: SectionNames.docsets, animatingDifferences: true)
    }
    .disposed(by: disposeBag)

    if !isForCollapsedSidebar {
      sceneState.currentScope
        .drive(with: self) { owner, scope in
          let indexPath: IndexPath? = { scope in
            if case let .docset(docset) = scope {
              if let res = owner.dataSource.indexPath(for: DocsetsListModel.docset(.docset(docset))) {
                return res
              }
            }
            return nil
          }(scope)
          owner.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .top)
        }
        .disposed(by: disposeBag)
    }

    collectionView.rx.itemSelected
      .subscribe(with: self) { owner, indexPath in
        guard !owner.isEditingRelay.value else {
          return
        }
        owner.collectionView.deselectItem(at: indexPath, animated: false)
        guard let dataSource = owner.dataSource, let model = dataSource.itemIdentifier(for: indexPath) else {
          return
        }
        switch model {
        case .header:
          break
        case .docset(let docset):
          switch docset {
          case let .docset(docset):
            owner.sceneState.dispatch(action: .updateCurrentScope(.docset(docset)))
          case let .broken(installation):
            GlobalUI.presentAlertController(
              UIAlertController.alert(
                withTitle: "Uninstall",
                message: "Do you really want to uninstall \(installation.name)",
                confirmAction: (
                  "Confirm",
                  UIAlertAction.Style.destructive,
                  { [libraryDocsetsManager = owner.libraryDocsetsManager] in
                    try? libraryDocsetsManager.uninstallDocset(forRecord: installation)
                  }
                ),
                cancelAction: (UIKitLocalizations.cancel, nil)
              )
            )
          }
        }
      }
      .disposed(by: disposeBag)
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateNavBarAppearance()
  }

  private func updateNavBarAppearance() {
    configureNavigationBarAppearance(enforceLargeTitle: true)
  }

}

extension HomeViewController: UICollectionViewDelegate {

  public func collectionView(
    _ collectionView: UICollectionView,
    contextMenuConfigurationForItemAt indexPath: IndexPath,
    point: CGPoint
  ) -> UIContextMenuConfiguration? {
    guard let collectionView = collectionView as? HomeCollectionView else {
      reportIssue("Unexpected collectionView type")
      return nil
    }
    return collectionView.itemContextMenuConfiguration(forIndexPath: indexPath)
  }

}
