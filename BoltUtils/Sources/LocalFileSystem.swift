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

public struct LocalFileSystem {

  private static let _libraryAbsolutePath: String! = {
    #if os(macOS) || targetEnvironment(macCatalyst)
    return NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first
    #else
    return NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first
    #endif
  }()

  private static let _documentsAbsolutePath: String! = {
    return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
  }()

  private static let _cachesAbsolutePath: String! = {
    return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
  }()

  private static let _tempAbsolutePath: String! = {
    return FileManager.default.temporaryDirectory.path
  }()

  public static let documentsAbsolutePath: String = {
    return _documentsAbsolutePath!
  }()

  public static let libraryAbsolutePath: String = {
    return _libraryAbsolutePath!
  }()

  public static let cachesAbsolutePath: String = {
    return _cachesAbsolutePath!
  }()

  public static let tempAbsolutePath: String = {
    return _tempAbsolutePath!
  }()

}
