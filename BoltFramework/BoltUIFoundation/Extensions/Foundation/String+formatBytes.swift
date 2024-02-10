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

// swiftlint:disable all

import Foundation

private let units = {
  let k = 1000.0
  let mb = k * k
  let gb = mb * k
  let tb = gb * k
  let pb = tb * k

  return [
    // (limit, divisor, format)
    (1,        1, "%.0f bytes"), // 0 bytes
    (k,        1, "%.0f bytes"), // 999 bytes
    (10 * k,   k, "%.1f KB"   ), // 9.9 KB
    (mb,       k, "%.0f KB"   ), // 999 KB
    (10 * mb, mb, "%.1f MB"   ), // 9.9 MB
    (gb,      mb, "%.0f MB"   ), // 999 MB
    (10 * gb, gb, "%.1f GB"   ), // 9.9 GB
    (tb,      gb, "%.0f GB"   ), // 999 GB
    (10 * tb, tb, "%.1f TB"   ), // 9.9 TB
    (pb,      tb, "%.0f TB"   ), // 999 TB
    (10 * pb, pb, "%.1f PB"   ), // 9.9 PB
    (k * pb,  pb, "%.0f PB"   ), // 999 PB
  ]
}()

public extension String {

  static func formatBytes(bytes: Double) -> String {
    if bytes <= 0 { return "0 bytes" }

    for unit in units {
      if bytes < unit.0 {
        return String(format: unit.2, bytes / unit.1)
      }
    }

    return "∞"
  }

}

// swiftlint:enable all
