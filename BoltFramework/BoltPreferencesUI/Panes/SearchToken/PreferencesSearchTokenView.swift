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

import SwiftUI
import UIKit

import BoltLocalizations
import BoltTypes
import BoltUIFoundation

struct PreferencesTypeBrowserView: UIViewControllerRepresentable {

  func makeUIViewController(context: Context) -> UINavigationController {
    return UINavigationController(rootViewController: PreferencesTypeBrowserViewController())
  }

  func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    // nothing to do here
  }

}

final class PreferencesTypeBrowserViewController: UITableViewController, UISearchResultsUpdating, SearchBarProvider {

  private var entryTypes: [EntryType] {
    return EntryType.typeDict.sorted { $0.value.singular < $1.value.singular }.map { $0.1 }
  }

  private var filteredEntryTypes = [EntryType]()

  private lazy var searchController: UISearchController = {
    let searchController = UISearchController(searchResultsController: nil)
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    return searchController
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TypeCell")

    title = "Search Tokens"

    let rightButton = UIBarButtonItem(
      title: UIKitLocalizations.done,
      style: UIBarButtonItem.Style.done,
      target: self,
      action: #selector(doneButtonTap(_:))
    )
    navigationItem.rightBarButtonItem = rightButton

    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false
    if #available(iOS 16, *) {
      navigationItem.preferredSearchBarPlacement = .stacked
    }

    definesPresentationContext = true
  }

  // MARK: - UITableViewDataSource

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return isFiltering() ? filteredEntryTypes.count : entryTypes.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let type = isFiltering() ? filteredEntryTypes[indexPath.row] : entryTypes[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "TypeCell", for: indexPath)
    var contentConfiguration = UIListContentConfiguration.cell()
    contentConfiguration.text = type.singular
    contentConfiguration.image = type.iconImage.image
    contentConfiguration.imageProperties.maximumSize = CGSize(width: 20, height: 20)
    cell.contentConfiguration = contentConfiguration
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    updateSearchToken(forIndexPath: indexPath)
  }

  // MARK: - UISearchResultsUpdating

  func updateSearchResults(for searchController: UISearchController) {
    let searchText = searchController.searchBar.text ?? ""
    if searchText.isEmpty {
      filteredEntryTypes = entryTypes
    } else {
      filteredEntryTypes = entryTypes.filter { $0.singular.lowercased().contains(searchText.lowercased()) }
    }
    tableView.reloadData()
  }

  // MARK: - Helper Methods

  private func updateSearchToken(forIndexPath indexPath: IndexPath) {
    let type = entryTypes[indexPath.row]
    let image = type.iconImage.image.resized(to: CGSize(width: 16, height: 16))
    let token = UISearchToken(icon: image, text: type.singular)

    searchBar.searchTextField.tokens = [token]
    searchBar.searchTextField.tokenBackgroundColor = type.colorResource.platformColor
  }

  private func isFiltering() -> Bool {
    return searchController.isActive
  }

  @objc private func doneButtonTap(_ sender: Any?) {
    dismiss(animated: true)
  }

}
