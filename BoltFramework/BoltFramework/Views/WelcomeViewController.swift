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

import SwiftUI
import UIKit

import SnapKit

import BoltUIFoundation

private struct WelcomeView: View {

  var body: some View {
    ZStack(alignment: .center) {
      Text("Framework-WelcomeController-welcomeTip".boltLocalized)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

}

final class WelcomeViewController: UIViewController {

  private var contentViewController = UIHostingController(rootView: WelcomeView())

  init() {
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Framework-WelcomeController-title".boltLocalized

    configureNavigationBarAppearance(enforceLargeTitle: false)
    addChild(contentViewController) {
      view.addSubview($0)
      $0.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }
    }
  }

}
