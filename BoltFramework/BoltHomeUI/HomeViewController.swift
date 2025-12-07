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
import BoltUtils

enum HomeListSection: Hashable {
  case docsets
  case favorites
  case history

  var localized: String {
    switch self {
    case .docsets:
      return "Home-List-SectionTitles-docsets".boltLocalized
    case .favorites:
      return "Home-List-SectionTitles-favorites".boltLocalized
    case .history:
      return "Home-List-SectionTitles-history".boltLocalized
    }
  }
}

enum DocsetsListModel: Hashable {
  case header(HomeListSection)
  case docset(HomeListItemViewModel)
}

public final class HomeViewController: BaseViewController, SearchBarProvider {

  private struct BarButtonItems {
    var leftItems: [UIBarButtonItem]
    var rightItems: [UIBarButtonItem]
  }

  @Injected(\.analyticsService)
  private var analyticsService: AnalyticsService?

  @Injected(\.libraryDocsetsManager)
  private var libraryDocsetsManager: LibraryDocsetsManager

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
        guard let self = self else {
          return
        }
        listViewController.deleteItems(atIndexPaths: listViewController.selectedIndexPathsForEditing)
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

  private lazy var listViewController: HomeListViewController = {
    HomeListViewController(isForCollapsedSidebar: isForCollapsedSidebar)
  }()

  private func setupToolbar() {
    navigationController?.setToolbarHidden(false, animated: true)

    let barButtonItems = isEditingObservable.map { [weak self, isForCollapsedSidebar] isEditing -> BarButtonItems in
      if isEditing {
        let doneButtonItem = UIBarButtonItem(
          systemItem: .done,
          primaryAction: UIAction { [weak self] _ in
            self?.isEditingRelay.accept(false)
          }
        )
        if !RuntimeEnvironment.isOS26UIEnabled {
          doneButtonItem.tintColor = UIColor.tintColor
        }
        if RuntimeEnvironment.isOS26UIEnabled, !isForCollapsedSidebar {
          return BarButtonItems(leftItems: [doneButtonItem], rightItems: [])
        } else {
          return BarButtonItems(leftItems: [], rightItems: [doneButtonItem])
        }
      } else {
        let moreButtonIconName = {
          if RuntimeEnvironment.isOS26UIEnabled {
            return "ellipsis"
          } else {
            return "ellipsis.circle"
          }
        }()
        let moreButtonItem = UIBarButtonItem(
          title: nil,
          image: UIImage(systemName: moreButtonIconName),
          primaryAction: nil,
          menu: UIMenu(
            title: "",
            children: update(
              [
                UIAction(
                  title: UIKitLocalizations.select,
                  image: UIImage(systemName: "checkmark.circle")
                ) { [weak self] _ in
                  self?.isEditingRelay.accept(true)
                },
              ]
            ) {
              if RuntimeEnvironment.isInternalBuild {
                $0.append(Self.createDiagnosticsMenu())
              }
            }
          )
        )
        if !RuntimeEnvironment.isOS26UIEnabled {
          moreButtonItem.tintColor = UIColor.tintColor
        }
        return BarButtonItems(leftItems: [], rightItems: [moreButtonItem])
      }
    }

    barButtonItems
      .subscribe(with: self) { owner, items in
        owner.navigationItem.leftBarButtonItems = items.leftItems
        owner.navigationItem.rightBarButtonItems = items.rightItems
      }
      .disposed(by: disposeBag)

    Driver.combineLatest(
      isEditingRelay.asDriver(),
      listViewController.selectedIndexPathsForEditingDriver,
    )
    .map { isEditing, indexPaths -> Bool in
      return isEditing && !indexPaths.isEmpty
    }
    .drive(toolbarTrashItem.rx.isEnabled)
    .disposed(by: disposeBag)

    let toolbarItems = isEditingRelay.map { [weak self, toolbarTrashItem] isEditing -> [UIBarButtonItem] in
      var items = isEditing ? [
        toolbarTrashItem,
        .flexibleSpace(),
      ] : [
        update(UIBarButtonItem()) {
          $0.primaryAction = UIAction(
            image: UIImage(systemName: "gear")
          ) { [weak self] _ in
            self?.sceneState.dispatch(action: .onPresentPreferences)
          }
        },
        .flexibleSpace(),
        UIBarButtonItem(
          customView: update(ToolbarDownloadsItemView()) {
            $0.downloadsButtonAction = { [weak self] in
              self?.sceneState.dispatch(action: .onPresentDownloads)
            }
            $0.updatesButtonAction = { [weak self] in
              self?.sceneState.dispatch(action: .onPresentUpdates)
            }
          }
        ),
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
            sceneState.dispatch(action: .onPresentLibrary)
          }
        }
      )
      return items
    }

    toolbarItems
      .bind(to: rx.toolbarItems)
      .disposed(by: disposeBag)
  }

  private func setupListViewController() {
    addChild(listViewController) {
      view.addSubview($0)
      $0.snp.makeConstraints { make in
        make.top.equalToSuperview()
        make.leading.equalTo(view.safeAreaLayoutGuide)
        make.trailing.equalTo(view.safeAreaLayoutGuide)
        make.bottom.equalToSuperview()
      }
    }
    isEditingRelay
      .bind(to: listViewController.isEditingObserver)
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
    searchBar.placeholder = UIKitLocalizations.search
  }

  var docsets = BehaviorRelay<[LibraryInstallationQueryResult]>(value: [])

  var dataSource: UICollectionViewDiffableDataSource<HomeListSection, DocsetsListModel> {
    return listViewController.dataSource
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    title = "Home-List-title".boltLocalized

    view.backgroundColor = .secondarySystemBackground

    updateNavBarAppearance()

    setupToolbar()
    setupSearchController()
    setupListViewController()

    dataSource.reorderingHandlers.canReorderItem = { _ in return true }

    dataSource.reorderingHandlers.didReorder = { [libraryDocsetsManager] transaction in
      guard let docsetSectionTransaction = transaction
        .sectionTransactions
        .first(where: { $0.sectionIdentifier == HomeListSection.docsets })
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
          case let .docset(viewModel):
            return viewModel.record
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

    var dataSourceSnapshot = NSDiffableDataSourceSnapshot<HomeListSection, DocsetsListModel>()
    dataSourceSnapshot.appendSections([
      HomeListSection.docsets,
      HomeListSection.favorites,
      HomeListSection.history,
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
        let headerDocsetsListModel = DocsetsListModel.header(.docsets)
        $0.append([headerDocsetsListModel])

        let symbolDocsetsListModelArray = docsets.map {
          DocsetsListModel.docset(HomeListItemViewModel(queryResult: $0))
        }
        $0.append(symbolDocsetsListModelArray, to: headerDocsetsListModel)

        $0.expand([headerDocsetsListModel])
      }
    }
    .drive { [dataSource] snapshot in
      dataSource.apply(snapshot, to: HomeListSection.docsets, animatingDifferences: true)
    }
    .disposed(by: disposeBag)

    if !isForCollapsedSidebar {
      sceneState.currentScope
        .drive(with: self) { owner, scope in
          let indexPath: IndexPath? = { scope in
            if case let .docset(docset) = scope {
              let docsetsSecctionSnapshot = owner.dataSource.snapshot(for: HomeListSection.docsets)
              if let item = docsetsSecctionSnapshot.items.first(where: { listModel in
                switch listModel {
                case .docset(let viewModel):
                  return viewModel.docset?.uuid == docset.uuid
                default:
                  return false
                }
              }) {
                return owner.dataSource.indexPath(for: item)
              }
            }
            return nil
          }(scope)
          owner.listViewController.selectItem(at: indexPath, animated: true, scrollPosition: .top)
        }
        .disposed(by: disposeBag)
    }

    listViewController.itemSelectedSignal
      .emit(with: self) { owner, indexPath in
        guard let model = owner.dataSource.itemIdentifier(for: indexPath) else {
          return
        }
        switch model {
        case .header:
          break
        case .docset(let viewModel):
          if let docset = viewModel.docset {
            owner.sceneState.dispatch(action: .updateCurrentScope(.docset(docset)))
          } else {
            let installation = viewModel.record
            GlobalUI.presentAlertController(
              UIAlertController.alert(
                withTitle: "Home-List-RemoveDamagedDocsetAlert-title".boltLocalized,
                message: "Home-List-RemoveDamagedDocsetAlert-message".boltLocalized(installation.name),
                confirmAction: (
                  UIKitLocalizations.ok,
                  UIAlertAction.Style.default,
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
