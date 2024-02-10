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

import Factory

import BoltTypes
import BoltUtils

public extension Container {
  var repositoryModuleInitializer: Factory<() -> Void> {
    var initialized = Atomic<Bool>(false)
    return self { {
      guard !initialized.value else {
        return
      }

      initialized.value = true

      let repositoryRegistry = Container.shared.repositoryRegistry()
      repositoryRegistry.registerRepository(CustomFeedRepository(), forIdentifier: .custom)
      // swiftlint:disable:next closure_end_indentation
    } }
  }
}
