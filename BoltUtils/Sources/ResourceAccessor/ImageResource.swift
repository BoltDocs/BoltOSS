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

public struct BoltImageResource {

  public var name: String
  public var bundle: Bundle

  public init(named name: String, in bundle: Bundle) {
    self.name = name
    self.bundle = bundle
  }

  public var platformImage: PlatformImage? {
    #if os(iOS)
    return PlatformImage(named: name, in: bundle, compatibleWith: nil)
    #else
    return bundle.image(forResource: name)
    #endif
  }

}
