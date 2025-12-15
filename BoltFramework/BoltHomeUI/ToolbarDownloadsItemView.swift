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

import Factory
import Overture
import SnapKit

import BoltDocsets
import BoltUtils

private final class ItemButton: UIButton {

  override var intrinsicContentSize: CGSize {
    if let labelSize = titleLabel?.intrinsicContentSize {
      return labelSize
    }
    return super.intrinsicContentSize
  }

}

final class ToolbarDownloadsItemView: UIView {

  @Injected(\.libraryDocsetsManager)
  private var libraryDocsetsManager: LibraryDocsetsManager

  var downloadsButtonAction: (() -> Void)?
  var updatesButtonAction: (() -> Void)?

  private var cancellables = Set<AnyCancellable>()

  private var stackView: UIStackView = {
    update(UIStackView()) {
      $0.axis = .vertical
      $0.alignment = .center
      $0.spacing = 0
      $0.distribution = .fill
    }
  }()

  private var downloadsButton: UIButton = {
    update(ItemButton(type: .system)) {
      $0.setTitle("Home-Toolbar-DownloadsButtonTitle".boltLocalized, for: .normal)
      $0.titleLabel?.font = UIFont.systemFont(ofSize: 17)
      if RuntimeEnvironment.isOS26UIEnabled {
        $0.tintColor = .label
      }
    }
  }()

  private var updatesButton: UIButton = {
    update(ItemButton(type: .system)) {
      $0.setTitle("Home-Toolbar-UpdatesButtonTitle".boltLocalized, for: .normal)
      $0.titleLabel?.font = UIFont.systemFont(ofSize: 11)
      if RuntimeEnvironment.isOS26UIEnabled {
        $0.tintColor = .label
      }
    }
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    clipsToBounds = true

    addSubview(stackView)
    stackView.snp.makeConstraints {
      $0.centerY.equalTo(self)
      $0.horizontalEdges.equalTo(self).inset(10)
    }

    downloadsButton.addTarget(self, action: #selector(downloadsButtonTap(_:)), for: .touchUpInside)
    updatesButton.addTarget(self, action: #selector(updatesButtonTap(_:)), for: .touchUpInside)

    updatesButton.setContentHuggingPriority(.required, for: .vertical)
    stackView.addArrangedSubview(downloadsButton)
    stackView.addArrangedSubview(updatesButton)

    libraryDocsetsManager
      .installedRecordsPublisher
      .map { $0.contains { $0.hasNewerVersion } }
      .sink { [weak self] updateAvailable in
        self?.updatesButton.isHidden = !updateAvailable
      }
      .store(in: &cancellables)
  }

  @objc private func downloadsButtonTap(_ sender: Any?) {
    downloadsButtonAction?()
  }

  @objc private func updatesButtonTap(_ sender: Any?) {
    updatesButtonAction?()
  }

}
