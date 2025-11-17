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
import Foundation

import BoltCombineExtensions
import BoltModuleExports

final class FindInPageToolbarViewModel {

  @Published private(set) var resultsText: String = "0"

  private(set) var currentIndex: Int = 0 {
    didSet { updateResultsText() }
  }

  private(set) var totalResults: Int = 0 {
    didSet { updateResultsText() }
  }

  private var sceneState: SceneState

  private var cancellables = Set<AnyCancellable>()

  init(sceneState: SceneState) {
    self.sceneState = sceneState

    sceneState.findInPageCurrentIndex
      .asPublisher()
      .ignoreFailure()
      .weakAssign(to: \.currentIndex, on: self)
      .store(in: &cancellables)

    sceneState.findInPageTotalResults
      .asPublisher()
      .ignoreFailure()
      .weakAssign(to: \.totalResults, on: self)
      .store(in: &cancellables)

    updateResultsText()
  }

  func previousButtonTapped() {
    sceneState.dispatch(action: .findPreviousInPage)
  }

  func nextButtonTapped() {
    sceneState.dispatch(action: .findNextInPage)
  }

  private func updateResultsText() {
    if totalResults == 0 {
      resultsText = "0"
    } else {
      resultsText = "\(currentIndex)/\(totalResults)"
    }
  }

}
