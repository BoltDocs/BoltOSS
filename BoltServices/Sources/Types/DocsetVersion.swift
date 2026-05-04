//
// Copyright (C) 2026 Bolt Contributors
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

public struct DocsetVersion: Sendable, RawRepresentable, Hashable {

  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public var displayVersion: String {
    guard let slashIndex = rawValue.firstIndex(of: "/") else {
      return rawValue
    }
    return String(rawValue[rawValue.startIndex..<slashIndex])
  }

  public var identifierString: String {
    rawValue.replacingOccurrences(of: "/", with: "_")
  }

}

extension DocsetVersion: LosslessStringConvertible {

  public init?(_ description: String) {
    self.init(rawValue: description)
  }

  public var description: String { rawValue }

}

extension DocsetVersion: Codable {

  public func encode(to encoder: any Encoder) throws {
    var encoder = encoder.singleValueContainer()
    try encoder.encode(rawValue)
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    rawValue = try container.decode(String.self)
  }

}
