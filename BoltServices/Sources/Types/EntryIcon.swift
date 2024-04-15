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

public enum EntryIcon: Hashable {

  case bundled(name: String)
  case data(_: Data)
  case providerDefault

  public var platformImage: PlatformImage? {
    switch self {
    case .bundled(let name):
      return BoltImageResource(named: name, in: .module).platformImage
    case .data(let imageData):
      return PlatformImage(data: imageData)
    case .providerDefault:
      return nil
    }
  }

}

public protocol EntryIconProvider {

  var icon: EntryIcon { get }
  static var defaultIconImage: PlatformImage { get }

  var iconImage: PlatformImage { get }

}

public extension EntryIconProvider {

  var iconImage: PlatformImage {
    return icon.platformImage ?? Self.defaultIconImage
  }

}
