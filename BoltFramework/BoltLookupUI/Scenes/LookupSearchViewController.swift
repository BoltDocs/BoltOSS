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

import IssueReporting
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

  private let sceneState: SceneState

  private let state: LookupRoutingState

  private let resultsController: LookupSearchResultsController

  private var preservedSearchFieldText: SearchTextFieldTextPreservation?

  private lazy var searchInputAccessoryToolbar: SearchInputAccessoryToolbar = {
    let findInPageViewModel = FindInPageToolbarViewModel(sceneState: sceneState)
    return SearchInputAccessoryToolbar(findInPageViewModel: findInPageViewModel)
  }()

  private lazy var searchInputAccessoryView: UIView = {
    let toolbarBottomPadding: CGFloat = RuntimeEnvironment.isOS26UIEnabled ? 10 : 0
    var bounds = CGRect(origin: .zero, size: searchInputAccessoryToolbar.bounds.size)
    bounds.size.height += toolbarBottomPadding
    let inputView = UIView(frame: bounds)
    inputView.addSubview(searchInputAccessoryToolbar)
    searchInputAccessoryToolbar.snp.makeConstraints {
      $0.top.leading.trailing.equalToSuperview()
      $0.bottom.equalToSuperview().inset(toolbarBottomPadding)
    }
    return inputView
  }()

  public init(sceneState: SceneState) {
    self.sceneState = sceneState
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

  override public func viewDidLoad() {
    super.viewDidLoad()

    showsSearchResultsController = true
    automaticallyShowsCancelButton = true
    hidesNavigationBarDuringPresentation = true
    obscuresBackgroundDuringPresentation = false
    scopeBarActivation = .onSearchActivation

    with(searchBar) {
      $0.delegate = self
      $0.placeholder = UIKitLocalizations.search
      $0.inputAccessoryView = searchInputAccessoryView
      $0.scopeButtonTitles = LookupSearchScope.allCases.map { $0.displayTitle }
      with($0.searchTextField) {
        $0.delegate = self
        $0.autocorrectionType = .no
        $0.allowsCopyingTokens = false
        $0.allowsDeletingTokens = false
        $0.autocapitalizationType = .none
        if RuntimeEnvironment.isOS26UIEnabled, UIDevice.isPadOrCatalyst {
          $0.clearButtonMode = .whileEditing
        }
      }
    }

    Observable.merge([ rx.willPresent.map { true }, rx.willDismiss.map { false } ])
      .subscribe(with: state) { owner, isActive in
        owner.onChangeSearchActive(isActive)
      }
      .disposed(by: disposeBag)

    state.presentsLookupListDriver
      .drive(with: self) { owner, presentsLookupList in
        owner.showsSearchResultsController = presentsLookupList
        owner.searchInputAccessoryToolbar.scope = presentsLookupList ? .types : .docPage
      }
      .disposed(by: disposeBag)

    state.searchScope
      .map { $0.index }
      .drive(searchBar.rx.selectedScopeButtonIndex)
      .disposed(by: disposeBag)

    state.hasTableOfContents
      .drive(with: self) { owner, hasTableOfContents in
        owner.searchBar.scopeButtonTitles = hasTableOfContents ? [
          LookupSearchScope.types.displayTitle,
          LookupSearchScope.docPage.displayTitle,
          LookupSearchScope.tableOfContents.displayTitle,
        ] : [
          LookupSearchScope.types.displayTitle,
          LookupSearchScope.docPage.displayTitle,
        ]
        owner.scopeBarSetNeedsLayout()
      }
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

    state.updateSearchText
      .emit(to: searchBar.rx.text)
      .disposed(by: disposeBag)

    state.dismissSearchDriver
      .emit(with: self) { owner, _ in
        owner.isActive = false
      }
      .disposed(by: disposeBag)

    searchBar.rx.value
      .map { return $0 ?? "" }
      .subscribe(with: self) { owner, searchQuery in
        owner.state.updateSearchQuery(searchQuery)
      }
      .disposed(by: disposeBag)
  }

  // MARK: Interfaces

  func presentTableOfContents() {
    isActive = true
    state.selectSearchScope(.tableOfContents)
  }

  // MARK: Private

  private func scopeBarSetNeedsLayout() {
    if let containerView = searchBar.scopeBar?.superview {
      #if DEBUG
      assert(String(describing: type(of: containerView)) == "_UISearchBarScopeContainerView")
      #endif
      containerView.setNeedsLayout()
    }
  }

}

// MARK: Search Field Text Preservation

private extension LookupSearchController {

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

  public func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange index: Int) {
    guard let selectedScope = SearchScope(index: index) else {
      reportIssue("unknown search scope index: \(index)")
      return
    }
    state.selectSearchScope(selectedScope)
  }

  public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    preserveSearchFieldText()
  }

  public func textFieldDidBeginEditing(_ textField: UITextField) {
    restoreSearchFieldText()
  }

  public func textFieldDidEndEditing(_ textField: UITextField) {
    restoreSearchFieldText()
  }

}
