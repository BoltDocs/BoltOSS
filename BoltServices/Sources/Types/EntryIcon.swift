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

import Foundation

import BoltTypesAssets
import BoltUtils

public enum EntryIcon: Sendable, Hashable {

  public enum Bundled: Sendable, Hashable {
    case name(_: String)
    case docsetIcon(_: DocsetIcons)
  }

  case bundled(_: Bundled)
  case data(_: Data, identifier: String)
  case providerDefault

  public var platformImage: IdentifiableImage? {
    switch self {
    case .bundled(let icon):
      let iconName: String
      switch icon {
      case let .name(name):
        iconName = name
      case let .docsetIcon(docsetIcon):
        iconName = "docset-icons/\(docsetIcon.rawValue)"
      }
      guard let image = BoltImageResource(named: iconName, in: BLTTypes.assetsBundle).platformImage else {
        return nil
      }
      return IdentifiableImage(image: image, id: iconName)
    case let .data(imageData, identifier):
      guard let image = PlatformImage(data: imageData) else {
        return nil
      }
      return IdentifiableImage(image: image, id: identifier)
    case .providerDefault:
      return nil
    }
  }

}

public protocol EntryIconProvider {

  var icon: EntryIcon { get }
  static var defaultIconImage: IdentifiableImage { get }

  var iconImage: IdentifiableImage { get }

}

public extension EntryIconProvider {

  var iconImage: IdentifiableImage {
    return icon.platformImage ?? Self.defaultIconImage
  }

}
