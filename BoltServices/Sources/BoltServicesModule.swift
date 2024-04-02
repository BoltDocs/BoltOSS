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

import BoltDocsets
import BoltRepository
import BoltRxSwift
import BoltTypes
import BoltUtils

public struct ServicesModule {

  public static var initialize: PerformOnce = {
    setupRxSwiftResourceTracing()
    LocalFileSystem.setupApplicationDirectories()
    Container.shared.repositoryModuleInitializer()()
    DocsetsModule.initialize()
    return {}
  }()

  private static func setupRxSwiftResourceTracing() {
    if Configurations.Debugging.enableRxSwiftResourceTracing {
      RxSwiftResourceTracing.setupRxSwiftResourceTracing(
        withInterval: Configurations.Debugging.rxSwiftResourceTracingInterval
      )
    }
  }

}

private extension LocalFileSystem {

  static func setupApplicationDirectories() {
    [
      applicationDocumentsAbsolutePath,
      applicationLibraryAbsolutePath,
      applicationCachesAbsolutePath,
      applicationTempAbsolutePath,
    ]
    .forEach { path in
      try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    }
  }

}
