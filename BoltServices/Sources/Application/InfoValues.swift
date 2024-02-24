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

import BoltUtils

public struct InfoValues {

  public static let appDisplayName = stringValue(forKey: "CFBundleDisplayName")
  public static let appVersion = stringValue(forKey: "CFBundleShortVersionString")
  public static let appBuildNumber = stringValue(forKey: "CFBundleVersion")
  public static let appCommit = stringValue(forKey: "BoltCommit")

  public static let bundleIdentifier = stringValue(forKey: "CFBundleIdentifier")

  public static var iconImage: PlatformImage? {
    #if !targetEnvironment(macCatalyst)
    if
      let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
      let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
      let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
      let lastIcon = iconFiles.last
    {
      return PlatformImage(named: lastIcon)
    }
    #else
    if
      let icon = Bundle.main.infoDictionary?["CFBundleIconName"] as? String,
      let icnsPath = Bundle.main.path(forResource: icon, ofType: "icns")
    {
      return PlatformImage(contentsOfFile: icnsPath)
    }
    #endif
    return nil
  }

  private static func stringValue(forKey key: String) -> String {
    return Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
  }

}
