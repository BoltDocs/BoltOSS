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

public extension Dictionary {

  mutating func switchKey(fromKey: Key, toKey: Key) {
    if let entry = removeValue(forKey: fromKey) {
      self[toKey] = entry
    }
  }

}

public extension Dictionary where Key == String, Value == Any {

  init?(propertyListData plistData: Data) {
    var format = PropertyListSerialization.PropertyListFormat.binary
    if let dict = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: &format) as? [String: Any] {
      self = dict
      return
    }
    return nil
  }

}
