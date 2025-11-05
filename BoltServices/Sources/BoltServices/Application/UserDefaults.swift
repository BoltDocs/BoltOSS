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

public struct UserDefaultKeys {

  public static let backgroundDownloadTaskIdentifiers = "backgroundDownloadTaskIdentifiers"

}

public extension UserDefaults {

  @objc dynamic var tintColor: String {
    get {
      return string(forKey: "tintColor") ?? ""
    }
    set {
      setValue(newValue, forKey: "tintColor")
    }
  }

  @objc dynamic var disablesPrivateBrowsing: Bool {
    get {
      return bool(forKey: "disablesPrivateBrowsing")
    }
    set {
      setValue(newValue, forKey: "disablesPrivateBrowsing")
    }
  }

  @objc dynamic var enablesDesktopMode: Bool {
    get {
      return bool(forKey: "enablesDesktopMode")
    }
    set {
      setValue(newValue, forKey: "enablesDesktopMode")
    }
  }

  @objc dynamic var updateCheckingFrequency: Int {
    get {
      if
        let value = object(forKey: "updateCheckingFrequency"),
          let intValue = value as? Int
      {
        return intValue
      }
      return -1
    }
    set {
      setValue(newValue, forKey: "updateCheckingFrequency")
    }
  }

  @objc dynamic var webViewInspectable: Bool {
    get {
      return bool(forKey: "webViewInspectable")
    }
    set {
      setValue(newValue, forKey: "webViewInspectable")
    }
  }

}
