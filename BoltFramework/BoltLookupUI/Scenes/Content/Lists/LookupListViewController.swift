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

import RxCocoa
import RxSwift
import SnapKit

import BoltUIFoundation
import BoltUtils

final class LookupListViewController<ListViewModel: LookupListViewModel>: BaseViewController, UITableViewDelegate {

  private var viewModel: ListViewModel

  init(viewModel: ListViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  private lazy var tableView = UITableView()

  private var activityIndicatorBarButtonItem: UIBarButtonItem = {
    let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
    activityIndicator.startAnimating()
    let barButtonItem = UIBarButtonItem(customView: activityIndicator)
    return barButtonItem
  }()

  private let currentError = BehaviorRelay<Error?>(value: nil)

  private lazy var contentUnavailableView = BoltContentUnavailableUIView(
    configuration: BoltContentUnavailableViewConfiguration(
      image: BoltImageResource(named: "warning", in: kFoundationBundle).platformImage!,
      imageSize: CGSize(width: 132, height: 132),
      message: "An Error Occurred",
      shouldDisplayIndicator: false,
      showsMessage: true,
      showsDetailButton: true,
      showsRetryButton: false
    ),
    // swiftlint:disable:next trailing_closure
    detailAction: { [weak self] in
      guard
        let self = self,
        let error = currentError.value
      else {
        return
      }
      GlobalUI.presentAlertController(
        UIAlertController.alert(
          withTitle: "An Error Occurred",
          message: error.localizedDescription,
          confirmAction: ("OK", .default, nil)
        )
      )
    }
  )

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground

    setupTableView()

    contentUnavailableView.isHidden = true
    view.addSubview(contentUnavailableView)
    contentUnavailableView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    // FIXME: .distinctUntilChanged() should be used

    viewModel.title
      .drive(navigationItem.rx.title)
      .disposed(by: disposeBag)

    viewModel.showsLoadingIndicator
      .map { [weak self] showsLoading in
        return showsLoading ? self?.activityIndicatorBarButtonItem : nil
      }
      .drive(navigationItem.rx.rightBarButtonItem)
      .disposed(by: disposeBag)

    viewModel.results
      .map { result -> [LookupListCellItem] in
        if case let .success(items) = result {
          return items
        }
        return []
      }
      .drive(tableView.rx.items(cellIdentifier: "EntryCell")) { _, reactor, cell in
        guard let cell = cell as? EntryCell else {
          return
        }
        cell.configure(forCellModel: reactor.viewModel)
      }
      .disposed(by: disposeBag)

    viewModel.results
      .map { result -> Error? in
        if case let .failure(error) = result {
          return error
        }
        return nil
      }
      .drive(currentError)
      .disposed(by: disposeBag)

    currentError
      .subscribe(with: self) { owner, error  in
        owner.contentUnavailableView.isHidden = (error == nil)
      }
      .disposed(by: disposeBag)
  }

  private func setupTableView() {
    tableView.register(UINib(nibName: "EntryCell", bundle: .module), forCellReuseIdentifier: "EntryCell")
    tableView.contentInset = view.safeAreaInsets

    tableView.backgroundColor = .systemBackground

    // Used to remove separators on empty cells
    tableView.tableFooterView = UIView()

    tableView.keyboardDismissMode = .onDrag

    tableView.rowHeight = 44
    tableView.sectionHeaderHeight = 44

    view.addSubview(tableView)
    tableView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    tableView.rx.itemSelected.subscribe(with: self) { owner, item in
      owner.tableView.deselectRow(at: item, animated: true)
    }
    .disposed(by: disposeBag)

    tableView.rx.modelSelected(LookupListCellItem.self)
      .bind(to: viewModel.itemSelected)
      .disposed(by: disposeBag)
  }

}

#if DEBUG

import BoltSearch
import BoltTypes

private struct LookupListStubbedEntryItem: LookupListCellItem {

  let viewModel: LookupListCellViewModel

  init(entry: Entry) {
    let type = entry.type ?? EntryType.unknown
    viewModel = LookupListCellViewModel(
      name: entry.name,
      prompt: "",
      shouldShowDisclosureIndicator: false,
      docsetIcon: nil,
      typeIcon: type.iconImage.image
    )
  }

}

private struct StubbedError: Error { }

private final class StubbedLookupListViewModel: LookupListViewModel {

  // MARK: - LookupListViewModel

  var title = Driver.just("Title")

  var showsLoadingIndicator = Driver.just(true)

  lazy var results: Driver<Result<[LookupListCellItem], Error>> = {
    switch entryItems {
    case let .success(items):
      return Driver.just(.success(items))
    case let .failure(error):
      return Driver.just(.failure(error))
    }
  }()

  var itemSelected = PublishRelay<LookupListCellItem>()

  // MARK: - Properties

  var entryItems: Result<[LookupListStubbedEntryItem], Error>

  init(entryItems: Result<[LookupListStubbedEntryItem], Error>) {
    self.entryItems = entryItems
  }

}

#Preview(traits: .fixedLayout(width: 480, height: 640)) {
  UINavigationController(
    rootViewController: LookupListViewController(
      viewModel: StubbedLookupListViewModel(
        entryItems: .success(
          [LookupListStubbedEntryItem](
            repeating: LookupListStubbedEntryItem(
              entry: Entry(typeName: "Class", name: "MyClass", rawPath: "")
            ),
            count: 10
          )
        )
      )
    )
  )
}

#Preview(traits: .fixedLayout(width: 480, height: 640)) {
  UINavigationController(
    rootViewController: LookupListViewController(
      viewModel: StubbedLookupListViewModel(
        entryItems: .failure(StubbedError())
      )
    )
  )
}

#endif
