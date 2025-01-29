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

public protocol LibraryRecord {

  var uuid: UUID { get }

  var uuidString: String { get }

  var name: String { get }

  var repository: RepositoryIdentifier { get }

  var version: String { get }

  var installedAsLatestVersion: Bool { get }

  var identifier: String { get }

}
