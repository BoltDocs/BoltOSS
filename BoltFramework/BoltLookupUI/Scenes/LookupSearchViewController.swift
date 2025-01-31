//
// Copyright (C) 2024 Bolt Contributors
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

import RxCocoa
import RxSwift

import BoltLocalizations
import BoltModuleExports
import BoltRxSwift
import BoltUIFoundation
import BoltUtils
import RoutableNavigation

private struct SearchTextFieldTextPreservation {

  let text: String?
  let tokens: [UISearchToken]

}

public final class LookupSearchController: UISearchController, HasDisposeBag {

  let state: LookupRoutingState!

  private let resultsController: LookupSearchResultsController

  private var preservedSearchFieldText: SearchTextFieldTextPreservation?

  public init(sceneState: SceneState) {
    self.state = LookupRoutingState(sceneState: sceneState)
    resultsController = LookupSearchResultsController(
      sceneState: sceneState,
      routingState: state
    )
    super.init(searchResultsController: resultsController)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  public func changeScope(_ scope: LookupScope) {
    state.changeScope(scope)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    showsSearchResultsController = true
    automaticallyShowsCancelButton = true
    hidesNavigationBarDuringPresentation = true
    obscuresBackgroundDuringPresentation = false

    with(searchBar) {
      $0.delegate = self
      $0.placeholder = UIKitLocalizations.search
      with($0.searchTextField) {
        $0.delegate = self
        $0.autocorrectionType = .no
        $0.allowsCopyingTokens = false
        $0.allowsDeletingTokens = false
        $0.autocapitalizationType = .none
      }
    }

    Observable.merge([ rx.willPresent.map { true }, rx.willDismiss.map { false } ])
      .subscribe(with: state) { owner, isActive in
        owner.onChangeSearchActive(isActive)
      }
      .disposed(by: disposeBag)

    state.presentsLookupList
      .drive(rx.showsSearchResultsController)
      .disposed(by: disposeBag)

    state.searchTokens
      .drive(with: self) { owner, tokens in
        let searchTextField = owner.searchBar.searchTextField
        searchTextField.tokens = tokens
      }
      .disposed(by: disposeBag)

    state.tokenColor
      .drive(with: self) { owner, color in
        let searchTextField = owner.searchBar.searchTextField
        searchTextField.tokenBackgroundColor = color?.platformColor
      }
      .disposed(by: disposeBag)

      searchBar.rx.value
        .map { return $0 ?? "" }
        .bind(to: state.searchQuery)
        .disposed(by: disposeBag)
  }

}

extension LookupSearchController: UITextFieldDelegate {

  public func textFieldDidChangeSelection(_ textField: UITextField) {
    // prevent selecting tokens
    guard
      let textField = textField as? UISearchTextField,
      let selectedTextRange = textField.selectedTextRange
    else {
      return
    }
    let beginning = textField.beginningOfDocument
    let offset = textField.offset(from: beginning, to: selectedTextRange.start)

    let tokenCount = textField.tokens.count
    if offset < tokenCount {
      guard
        let newStart = textField.position(from: beginning, offset: tokenCount),
        let newRange = textField.textRange(from: newStart, to: selectedTextRange.end)
      else {
        return
      }
      textField.selectedTextRange = newRange
    }
  }

  public func textField(
    _ textField: UITextField,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String
  ) -> Bool {
    // use range.lowerBound == -1 to determine that user deletes a search token
    if range.lowerBound == -1, string.isEmpty {
      DispatchQueue.main.async { [weak self] in
        self?.state.deselectEntryOrPop()
      }
    }
    return true
  }

}

extension LookupSearchController: UISearchBarDelegate {

  public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    preserveSearchFieldText()
  }

  public func textFieldDidBeginEditing(_ textField: UITextField) {
    restoreSearchFieldText()
  }

  public func textFieldDidEndEditing(_ textField: UITextField) {
    restoreSearchFieldText()
  }

  private func preserveSearchFieldText() {
    preservedSearchFieldText = SearchTextFieldTextPreservation(
      text: searchBar.searchTextField.text,
      tokens: searchBar.searchTextField.tokens
    )
  }

  private func restoreSearchFieldText() {
    guard let preservedSearchFieldText = self.preservedSearchFieldText else {
      return
    }
    searchBar.searchTextField.text = preservedSearchFieldText.text
    searchBar.searchTextField.tokens = preservedSearchFieldText.tokens
    searchBar.delegate?.searchBar?(searchBar, textDidChange: searchBar.text ?? "")
    self.preservedSearchFieldText = nil
  }

}
