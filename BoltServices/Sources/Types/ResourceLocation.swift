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

public protocol ResourceLocation {

  func appendingPathExtension(_ pathExtension: String) -> any ResourceLocation

}

public struct ResourceLocations {

  public static func URL(_ URL: URL) -> any ResourceLocation {
    return URLResourceLocation(URL: URL)
  }

}

public struct URLResourceLocation: ResourceLocation, Equatable {

  public private(set) var URL: URL

  public func appendingPathExtension(_ pathExtension: String) -> any ResourceLocation {
    return Self(URL: URL.appendingPathExtension(pathExtension))
  }

}
