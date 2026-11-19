//
// Copyright (C) 2026 Bolt Contributors
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

import BoltModuleExports
import BoltRxSwift
import BoltServices
import BoltUIFoundation
import BoltUtils

final class LookupBookmarkListViewController: UITableViewController, HasDisposeBag, LoggerProvider {

  var onSelectPage: ((String) -> Void)?
  var onToggleBookmark: (() -> Void)?

  private let viewModel: LookupBookmarkListViewModel

  private let docsetIcon: UIImage?

  lazy var bookmarkButtonItem = UIBarButtonItem(
    image: UIImage(systemName: "bookmark"),
    style: .plain,
    target: self,
    action: #selector(bookmarkButtonTapped)
  )

  init(context: LookupSheetContext) {
    viewModel = LookupBookmarkListViewModel(context: context)
    docsetIcon = context.docset.iconImageForList?.image
    super.init(style: .plain)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("\(#function) not implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground

    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Bookmark")

    bookmarkButtonItem.isEnabled = viewModel.canToggleBookmark

    viewModel.bookmarks
      .drive(with: self) { owner, _ in
        owner.tableView.reloadData()
      }
      .disposed(by: disposeBag)

    viewModel.currentPageBookmarked
      .drive(with: self) { owner, isBookmarked in
        owner.bookmarkButtonItem.image = UIImage(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
      }
      .disposed(by: disposeBag)
  }

  @objc private func bookmarkButtonTapped() {
    onToggleBookmark?()
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.bookmarksValue.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let bookmark = viewModel.bookmarksValue[indexPath.row]

    let cell = tableView.dequeueReusableCell(withIdentifier: "Bookmark", for: indexPath)

    let configuration = update(cell.defaultContentConfiguration()) {
      $0.text = bookmark.title
      if bookmark.path.isHTTPURL() {
        $0.image = UIImage(
          systemName: "globe",
          withConfiguration: PlatformImage.SymbolConfiguration(
            pointSize: 16
          )
        )!
      } else {
        $0.image = docsetIcon
      }
      $0.imageProperties.reservedLayoutSize = CGSize(width: 30, height: 30)
    }
    cell.contentConfiguration = configuration

    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    onSelectPage?(viewModel.bookmarksValue[indexPath.row].path)
    dismiss(animated: true)
  }

}
