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

import SnapKit

import BoltRxSwift

final class LookupSearchScopeBar: UIView {

  private let segmentedControl = UISegmentedControl()

  var titles = [String]() {
    didSet {
      guard titles != oldValue else {
        return
      }
      let selectedTitle = segmentedControl.selectedSegmentIndex >= 0
        ? segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)
        : nil
      segmentedControl.removeAllSegments()
      titles.enumerated().forEach { index, title in
        segmentedControl.insertSegment(withTitle: title, at: index, animated: false)
      }
      if let selectedTitle, let indexToRestore = titles.firstIndex(of: selectedTitle) {
        segmentedControl.selectedSegmentIndex = indexToRestore
      }
    }
  }

  lazy var selectedItemIndex: Binder<Int> = {
    Binder(segmentedControl) { segmentedControl, index in
      guard 0..<segmentedControl.numberOfSegments ~= index else {
        segmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        return
      }
      segmentedControl.selectedSegmentIndex = index
    }
  }()

  lazy var selectedIndexDidChange: Signal<Int> = {
    segmentedControl.rx.controlEvent(.valueChanged)
      .map { [segmentedControl] in segmentedControl.selectedSegmentIndex }
      .asSignal(onErrorSignalWith: .never())
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
    backgroundColor = UIColor.systemBackground

    addSubview(segmentedControl)
    segmentedControl.snp.makeConstraints {
      $0.height.equalTo(30)
      $0.horizontalEdges.equalToSuperview().inset(32)
      $0.verticalEdges.equalToSuperview().inset(12)
    }
  }

}
