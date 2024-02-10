//
// Copyright (C) 2023 Bolt Contributors
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

final class TripleColumnSplitViewController: UISplitViewController, UISplitViewControllerDelegate {

  init() {
    super.init(style: .tripleColumn)

    preferredSplitBehavior = .displace
    preferredDisplayMode = .twoDisplaceSecondary

    showsSecondaryOnlyButton = true
    displayModeButtonVisibility = .never

    delegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  func splitViewController(
    _ splitViewController: UISplitViewController,
    topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
  ) -> UISplitViewController.Column {
    return .primary
  }

}
