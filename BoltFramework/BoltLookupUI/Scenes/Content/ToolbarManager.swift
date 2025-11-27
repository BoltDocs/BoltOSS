//
// Copyright (C) 2025 Bolt Contributors
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

import Combine
import UIKit

import Overture

import BoltModuleExports
import BoltRxSwift

protocol ToolbarManagerDelegate: AnyObject {

  func toolbarManagerDidTapGoBack(_ toolbarManager: ToolbarManager)
  func toolbarManagerDidTapGoForward(_ toolbarManager: ToolbarManager)
  func toolbarManagerDidTapZoomIn(_ toolbarManager: ToolbarManager)
  func toolbarManagerDidTapZoomOut(_ toolbarManager: ToolbarManager)
  func toolbarManagerDidTapShare(_ toolbarManager: ToolbarManager)

}

enum ToolbarMode {
  case normal
  case findInPage
}

final class ToolbarManager {

  typealias Delegate = UIViewController & ToolbarManagerDelegate

  private weak var viewController: Delegate?

  var mode: ToolbarMode = .normal {
    didSet {
      if mode != oldValue {
        updateToolbarItems(forMode: mode)
      }
    }
  }

  private let findInPageViewModel: FindInPageToolbarViewModel

  private var cancellables = Set<AnyCancellable>()

  init(
    viewController: Delegate,
    findInPageToolbarViewModel: FindInPageToolbarViewModel
  ) {
    self.viewController = viewController
    self.findInPageViewModel = findInPageToolbarViewModel

    findInPageViewModel.$resultsText
      .receive(on: DispatchQueue.main)
      .sink { [weak self] text in
        guard let self = self else {
          return
        }
        findInPageResultCountLabel.text = text
      }
      .store(in: &cancellables)

    findInPageViewModel.$navigationButtonEnabled
      .receive(on: DispatchQueue.main)
      .sink { [weak self] enabled in
        guard let self = self else {
          return
        }
        findInPagePreviousButton.isEnabled = enabled
        findInPageNextButton.isEnabled = enabled
      }
      .store(in: &cancellables)

    updateToolbarItems(forMode: mode)
  }

  var backButtonEnabled: Binder<Bool> { backButton.rx.isEnabled }
  var forwardButtonEnabled: Binder<Bool> { forwardButton.rx.isEnabled }

  private lazy var backButton = UIBarButtonItem(
    image: UIImage(systemName: "chevron.left"),
    style: .plain,
    target: self,
    action: #selector(backButtonTapped(_:))
  )

  private lazy var forwardButton = UIBarButtonItem(
    image: UIImage(systemName: "chevron.right"),
    style: .plain,
    target: self,
    action: #selector(forwardButtonTapped(_:))
  )

  private lazy var tableOfContentsButton = UIBarButtonItem(
    image: UIImage(systemName: "list.bullet"),
    style: .plain,
    target: self,
    action: #selector(tableOfContentsButtonTapped(_:))
  )

  private lazy var bookmarkButton = UIBarButtonItem(
    image: UIImage(systemName: "bookmark"),
    style: .plain,
    target: self,
    action: #selector(bookmarkButtonTapped(_:))
  )

  private lazy var shareButton = UIBarButtonItem(
    image: UIImage(systemName: "square.and.arrow.up"),
    style: .plain,
    target: self,
    action: #selector(shareButtonTapped(_:))
  )

  private lazy var moreButton: UIBarButtonItem = {
    return UIBarButtonItem(
      image: UIImage(systemName: "textformat.size"),
      menu: UIMenu(
        title: "",
        children: [
          UIAction(title: "Smaller Text", image: UIImage(systemName: "textformat.size.smaller")) { [weak self] _ in
            guard let self = self else {
              return
            }
            viewController?.toolbarManagerDidTapZoomOut(self)
          },
          UIAction(title: "Larger Text", image: UIImage(systemName: "textformat.size.larger")) { [weak self] _ in
            guard let self = self else {
              return
            }
            viewController?.toolbarManagerDidTapZoomIn(self)
          },
        ]
      )
    )
  }()

  private lazy var findInPageResultCountLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 14)
    label.textColor = .secondaryLabel
    label.textAlignment = .left
    return label
  }()

  private lazy var findInPageResultCountItem: UIBarButtonItem = {
    let containerView = UIView()
    containerView.addSubview(findInPageResultCountLabel)
    findInPageResultCountLabel.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(6)
      make.trailing.equalToSuperview().offset(-6)
      make.top.bottom.equalToSuperview()
    }
    return UIBarButtonItem(customView: containerView)
  }()

  private lazy var findInPagePreviousButton: UIBarButtonItem = {
    let button = UIBarButtonItem(
      image: UIImage(systemName: "chevron.up"),
      style: .plain,
      target: self,
      action: #selector(findInPagePreviousButtonTapped)
    )
    return button
  }()

  private lazy var findInPageNextButton: UIBarButtonItem = {
    let button = UIBarButtonItem(
      image: UIImage(systemName: "chevron.down"),
      style: .plain,
      target: self,
      action: #selector(findInPageNextButtonTapped)
    )
    return button
  }()

  private func updateToolbarItems(forMode mode: ToolbarMode) {
    let toolbarItems: [UIBarButtonItem] = {
      let flexibleSpace = UIBarButtonItem.flexibleSpace()
      switch mode {
      case .normal:
        return [
          backButton,
          flexibleSpace,
          forwardButton,
          flexibleSpace,
          tableOfContentsButton,
          flexibleSpace,
          bookmarkButton,
          flexibleSpace,
          shareButton,
          flexibleSpace,
          moreButton,
        ]
      case .findInPage:
        return [flexibleSpace, findInPageResultCountItem, findInPagePreviousButton, findInPageNextButton]
      }
    }()
    viewController?.toolbarItems = toolbarItems
  }

  @objc func backButtonTapped(_ sender: Any?) {
    viewController?.toolbarManagerDidTapGoBack(self)
  }

  @objc func forwardButtonTapped(_ sender: Any?) {
    viewController?.toolbarManagerDidTapGoForward(self)
  }

  @objc func tableOfContentsButtonTapped(_ sender: Any?) {

  }

  @objc func bookmarkButtonTapped(_ sender: Any?) {

  }

  @objc func shareButtonTapped(_ sender: Any?) {
    viewController?.toolbarManagerDidTapShare(self)
  }

  @objc func findInPagePreviousButtonTapped(_ sender: Any?) {
    findInPageViewModel.previousButtonTapped()
  }

  @objc func findInPageNextButtonTapped(_ sender: Any?) {
    findInPageViewModel.nextButtonTapped()
  }

}
