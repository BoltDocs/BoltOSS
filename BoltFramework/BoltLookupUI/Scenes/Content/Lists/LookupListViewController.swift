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

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground

    setupTableView()

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
      .asDriver()
      .drive(self.tableView.rx.items(cellIdentifier: "EntryCell")) { _, reactor, cell in
        guard let cell = cell as? EntryCell else {
          return
        }
        cell.configure(forCellModel: reactor.viewModel)
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

    tableView.rx.itemSelected.subscribe { item in
      self.tableView.deselectRow(at: item, animated: true)
    }
    .disposed(by: disposeBag)

    tableView.rx.modelSelected(LookupListCellItem.self)
      .bind(to: viewModel.itemSelected)
      .disposed(by: disposeBag)
  }

}
