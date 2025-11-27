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
import SnapKit

final class FindInPageToolbar: UIToolbar {

  private let viewModel: FindInPageToolbarViewModel

  private var cancellables = Set<AnyCancellable>()

  private lazy var resultCountLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 14)
    label.textColor = .secondaryLabel
    label.textAlignment = .left
    return label
  }()

  private lazy var resultCountItem: UIBarButtonItem = {
    let containerView = UIView()
    containerView.addSubview(resultCountLabel)
    resultCountLabel.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(6)
      make.trailing.equalToSuperview().offset(-6)
      make.top.bottom.equalToSuperview()
    }
    return UIBarButtonItem(customView: containerView)
  }()

  private lazy var previousButton: UIBarButtonItem = {
    let button = UIBarButtonItem(
      image: UIImage(systemName: "chevron.up"),
      style: .plain,
      target: self,
      action: #selector(previousButtonTapped)
    )
    return button
  }()

  private lazy var nextButton: UIBarButtonItem = {
    let button = UIBarButtonItem(
      image: UIImage(systemName: "chevron.down"),
      style: .plain,
      target: self,
      action: #selector(nextButtonTapped)
    )
    return button
  }()

  init(viewModel: FindInPageToolbarViewModel) {
    self.viewModel = viewModel
    super.init(frame: .zero)
    setupToolbar()
    setupViewModelBindings()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("\(#function) is not implemented")
  }

  private func setupToolbar() {
    items = [.flexibleSpace(), resultCountItem, previousButton, nextButton]
    sizeToFit()
  }

  private func setupViewModelBindings() {
    cancellables.removeAll()

    viewModel.$resultsText
      .receive(on: DispatchQueue.main)
      .sink { [weak self] text in
        guard let self = self else {
          return
        }
        resultCountLabel.text = text
        resultCountItem.isHidden = text.isEmpty
      }
      .store(in: &cancellables)

    viewModel.$navigationButtonEnabled
      .receive(on: DispatchQueue.main)
      .sink { [weak self] enabled in
        guard let self = self else {
          return
        }
        previousButton.isEnabled = enabled
        nextButton.isEnabled = enabled
      }
      .store(in: &cancellables)
  }

  // MARK: - Actions

  @objc private func previousButtonTapped() {
    viewModel.previousButtonTapped()
  }

  @objc private func nextButtonTapped() {
    viewModel.nextButtonTapped()
  }

}
