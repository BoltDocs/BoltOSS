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

import BoltUtils

public extension LocalFileSystem {

  private static let applicationPathPrefix = {
    #if DEBUG
    return "BoltDebug"
    #else
    return "Bolt"
    #endif
  }()

  static let applicationDocumentsAbsolutePath: String = {
    return LocalFileSystem.documentsAbsolutePath.appendingPathComponent(applicationPathPrefix)
  }()

  static let applicationLibraryAbsolutePath: String = {
    return LocalFileSystem.libraryAbsolutePath.appendingPathComponent(applicationPathPrefix)
  }()

  static let applicationCachesAbsolutePath: String = {
    return LocalFileSystem.cachesAbsolutePath.appendingPathComponent(applicationPathPrefix)
  }()

  static let applicationTempAbsolutePath: String = {
    return LocalFileSystem.tempAbsolutePath.appendingPathComponent(applicationPathPrefix)
  }()

}
