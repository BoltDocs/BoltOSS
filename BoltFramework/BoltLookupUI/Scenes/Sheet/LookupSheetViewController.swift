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

import BoltModuleExports
import BoltTypes
import BoltUIFoundation

import SnapKit

struct LookupSheetContext {

  struct CurrentPage {
    let path: String
    let title: String
  }

  let docset: Docset
  let currentPage: CurrentPage?

}

@MainActor
protocol LookupSheetViewControllerDelegate: AnyObject {

  func lookupSheetViewController(_ viewController: LookupSheetViewController, didSelectPageWithPath path: String)
  func lookupSheetViewControllerOnToggleBookmark(_ viewController: LookupSheetViewController)

}

final class LookupSheetViewController: UIViewController {

  private weak var delegate: LookupSheetViewControllerDelegate?

  private let bookmarkListViewController: LookupBookmarkListViewController
  private let historyListViewController: LookupHistoryListViewController

  private var selectedViewController: UIViewController?

  private lazy var segmentedControl: UISegmentedControl = {
    let control = UISegmentedControl()
    control.insertSegment(with: UIImage(systemName: "book"), at: 0, animated: false)
    control.insertSegment(with: UIImage(systemName: "clock"), at: 1, animated: false)
    control.selectedSegmentIndex = 0
    control.addTarget(self, action: #selector(selectedSegmentDidChange(_:)), for: .valueChanged)
    return control
  }()

  private lazy var closeButton = UIBarButtonItem(
    barButtonSystemItem: .close,
    target: self,
    action: #selector(closeButtonTapped(_:))
  )

  private init(context: LookupSheetContext, delegate: LookupSheetViewControllerDelegate) {
    self.delegate = delegate

    bookmarkListViewController = LookupBookmarkListViewController(context: context)
    historyListViewController = LookupHistoryListViewController()

    super.init(nibName: nil, bundle: nil)

    bookmarkListViewController.onSelectPage = { [weak self] path in
      guard let self = self else {
        return
      }
      delegate.lookupSheetViewController(self, didSelectPageWithPath: path)
    }

    bookmarkListViewController.onToggleBookmark = { [weak self] in
      guard let self = self else {
        return
      }
      delegate.lookupSheetViewControllerOnToggleBookmark(self)
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("\(#function) not implemented")
  }

  static func present(
    from viewController: UIViewController,
    context: LookupSheetContext,
    delegate: LookupSheetViewControllerDelegate
  ) {
    let sheet = LookupSheetViewController(context: context, delegate: delegate)
    let navigationController = UINavigationController(rootViewController: sheet)
    navigationController.modalPresentationStyle = .formSheet
    viewController.present(navigationController, animated: true)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground

    navigationItem.titleView = segmentedControl

    updateSelectedViewController()
  }

  @objc private func closeButtonTapped(_ sender: UIBarButtonItem) {
    dismiss(animated: true)
  }

  @objc private func selectedSegmentDidChange(_ sender: UISegmentedControl) {
    updateSelectedViewController()
  }

  private func updateSelectedViewController() {
    let showsBookmarks = segmentedControl.selectedSegmentIndex == 0
    navigationItem.rightBarButtonItems = showsBookmarks ? [closeButton, bookmarkListViewController.bookmarkButtonItem] : [closeButton]

    let viewController: UIViewController = showsBookmarks
      ? bookmarkListViewController
      : historyListViewController

    if selectedViewController !== viewController {
      if let selectedViewController {
        removeChild(selectedViewController) {
          $0.removeFromSuperview()
        }
      }
      addChild(viewController) {
        view.addSubview($0)
        $0.snp.makeConstraints {
          $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
      }
      selectedViewController = viewController
    }
  }

}
