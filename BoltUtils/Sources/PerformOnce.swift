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

/// - SeeAlso: https://gist.github.com/rnapier/417153734150208dc8a18e3d6318255e

/// Useful when wanting to initialize something only once.
/// Use `return {}` at the end of the closure.
/// Example usage:
///   ```
///   static var initialize: PerformOnce = {
///       print("hello world")
///       return {}
///   }()
///   ```
public typealias PerformOnce = () -> Void
