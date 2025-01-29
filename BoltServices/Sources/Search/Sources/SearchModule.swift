//
// Copyright (C) 2025 Bolt Contributors
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

import Factory

import BoltUtils

public extension Container {

  private static var initialize: PerformOnce = {
    let _ = Container.shared.searchService.resolve()
    return {}
  }()

  var searchModuleInitializer: Factory<() -> Void> {
    return self { {
      Self.initialize()
      // swiftlint:disable:next closure_end_indentation
    } }
  }

}
