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

import Foundation
import UIKit

import Factory

import BoltServices

public struct AppearanceTypes {
  public enum TintColorKey: String {
    case purple
  }

  public struct TintColor {
    public var name: String
    public var color: UIColor
  }
}

public protocol AppearanceService {

  var availableTintColors: [(AppearanceTypes.TintColorKey, AppearanceTypes.TintColor)] { get }

  func setTintColor(_ key: AppearanceTypes.TintColorKey)

  func clearTintColor()

  var currentSelectedKey: AppearanceTypes.TintColorKey? { get }

}

class AppearanceServiceImp: AppearanceService {

  private let tintColorMap: [AppearanceTypes.TintColorKey: AppearanceTypes.TintColor] = [
    .purple: AppearanceTypes.TintColor(name: "Purple", color: UIColor(named: "AccentPurple", in: Bundle.module, compatibleWith: nil)!),
  ]

  private var selectedKey: AppearanceTypes.TintColorKey?

  required init() {
    if
      let key = AppearanceTypes.TintColorKey(rawValue: UserDefaults.standard.tintColor),
      let color = tintColorMap[key]?.color
    {
      updateTintColorForUI(color)
    }
  }

  lazy var availableTintColors: [(AppearanceTypes.TintColorKey, AppearanceTypes.TintColor)] = {
    return Array(tintColorMap)
  }()

  func setTintColor(_ key: AppearanceTypes.TintColorKey) {
    guard let tintColor = tintColorMap[key] else {
      return
    }
    updateTintColorForUI(tintColor.color)

    UserDefaults.standard.tintColor = key.rawValue
    selectedKey = key
  }

  func clearTintColor() {
    updateTintColorForUI(nil)

    UserDefaults.standard.tintColor = ""
    selectedKey = nil
  }

  var currentSelectedKey: AppearanceTypes.TintColorKey? {
    return selectedKey
  }

  private func updateTintColorForUI(_ color: UIColor?) {
    UIView.appearance().tintColor = color
    UIApplication.shared.refreshAllWindowAppearances()
  }

}

public extension Container {
  var appearanceService: Factory<AppearanceService> {
    self { AppearanceServiceImp() }
      .cached
  }
}
