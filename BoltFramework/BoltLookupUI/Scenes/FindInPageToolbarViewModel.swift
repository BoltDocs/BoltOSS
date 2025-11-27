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

  @Published private(set) var resultsText = ""
  @Published private(set) var navigationButtonEnabled = false

  @Published private var searchQueryEmpty = true
  @Published private var currentIndex = 0
  @Published private var totalResults = 0

  private var sceneState: SceneState

  private var cancellables = Set<AnyCancellable>()

  init(sceneState: SceneState) {
    self.sceneState = sceneState

    sceneState.findInPageQuery
      .asPublisher()
      .ignoreFailure()
      .map { $0.isEmpty }
      .weakAssign(to: \.searchQueryEmpty, on: self)
      .store(in: &cancellables)

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

    Publishers.CombineLatest($currentIndex, $totalResults)
      .map { currentIndex, totalResults in
        if totalResults == 0 {
          return "No Results"
        } else {
          return "\(currentIndex)/\(totalResults)"
        }
      }
      .weakAssign(to: \.resultsText, on: self)
      .store(in: &cancellables)

    Publishers.CombineLatest($searchQueryEmpty, $totalResults)
      .map { searchQueryEmpty, totalResults in
        !searchQueryEmpty && totalResults > 0
      }
      .weakAssign(to: \.navigationButtonEnabled, on: self)
      .store(in: &cancellables)
  }

  func previousButtonTapped() {
    sceneState.dispatch(action: .findPreviousInPage)
  }

  func nextButtonTapped() {
    sceneState.dispatch(action: .findNextInPage)
  }

}
