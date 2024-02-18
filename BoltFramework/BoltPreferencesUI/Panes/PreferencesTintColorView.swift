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

import Factory

import BoltLocalizations
import BoltUIFoundation
import BoltUtils

private class PreferencesTintColorViewModel: ObservableObject {

  @Injected(\.appearanceService)
  private var appearanceService: AppearanceService

  struct ItemViewModel: Hashable, Identifiable {
    enum TintColorKey: Hashable {
      case auto
      case specific(key: AppearanceTypes.TintColorKey)
    }

    var key: TintColorKey
    var color: UIColor

    var id: String {
      switch key {
      case .auto:
        return "auto"
      case let .specific(key: key):
        return key.rawValue
      }
    }
  }

  private (set) var items: [ItemViewModel] = []
  private (set) var selectedKey: ItemViewModel.TintColorKey = .auto

  init() {
    let tintColors = appearanceService.availableTintColors
    items.append(
      ItemViewModel(
        key: .auto,
        color: .systemBlue // FIXME: should be rainbow color for Macs
      )
    )
    items.append(
      contentsOf: tintColors.map { key, tintColor in
        ItemViewModel(
          key: .specific(key: key),
          color: tintColor.color
        )
      }
    )
    if let currentSelectedKey = appearanceService.currentSelectedKey {
      selectedKey = .specific(key: currentSelectedKey)
    }
  }

  func onTapItem(_ key: ItemViewModel.TintColorKey) {
    switch key {
    case .auto:
      appearanceService.clearTintColor()
    case let .specific(key: key):
      appearanceService.setTintColor(key)
    }
  }

}

struct PreferencesTintColorView: View {

  @Environment(\.dismiss)
  private var dismiss: DismissAction

  @StateObject private var viewModel = PreferencesTintColorViewModel()

  var body: some View {
    List {
      Section {
        HStack(spacing: 8) {
          ForEach(viewModel.items, id: \.self) { item in
            ZStack(alignment: .center) {
              Circle()
                .frame(width: 40, height: 40)
                .foregroundColor(Color(uiColor: item.color))
                .onTapGesture {
                  viewModel.onTapItem(item.key)
                  dismiss()
                }
              if item.key == viewModel.selectedKey {
                Image(systemName: "checkmark")
                  .foregroundColor(Color.white)
                  .frame(width: 24, height: 24)
              }
            }
          }
        }
      }
    }
    .navigationTitle("Preferences-TintColor-title".boltLocalized)
    .navigationBarTitleDisplayMode(.inline)
  }

}
