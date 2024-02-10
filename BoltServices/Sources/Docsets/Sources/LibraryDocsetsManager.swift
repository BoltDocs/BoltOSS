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

import Combine
import Foundation

import BoltDatabase
import BoltTypes
import BoltUtils

public enum LibraryInstallationQueryResult: Hashable {

  case docset(_: Docset)
  case broken(_: DocsetInstallation)

  public var installation: DocsetInstallation {
    switch self {
    case let .docset(docset):
      return docset.index
    case let .broken(installation):
      return installation
    }
  }

  public var displayName: String {
    switch self {
    case let .docset(docset):
      return docset.displayName
    case let .broken(installation):
      return installation.name
    }
  }

}

public class LibraryDocsetsManager: LoggerProvider {

  public static let shared = LibraryDocsetsManager()

  private var cancellables = Set<AnyCancellable>()

  private lazy var _installedDocsets = CurrentValueSubject<[LibraryInstallationQueryResult], Never>([])

  public func installedDocsets() -> AnyPublisher<[LibraryInstallationQueryResult], Never> {
    return _installedDocsets
      .eraseToAnyPublisher()
  }

  public func installedRecords() -> AnyPublisher<[LibraryRecord], Never> {
    return _installedDocsets
      .map { result in
        return result.map { res in
          switch res {
          case let .docset(docset):
            return docset
          case let .broken(installation):
            return installation
          }
        }
      }
      .eraseToAnyPublisher()
  }

  public init() {
    LibraryDatabase.shared.allDocsetInstallations
      .map { array in
        array.compactMap { installation -> LibraryInstallationQueryResult in
          if let docset = LibraryDocsetsFileSystemBridge.docset(withLibraryIndex: installation) {
            return .docset(docset)
          } else {
            return .broken(installation)
          }
        }
      }
      .assign(to: \.value, on: _installedDocsets)
      .store(in: &cancellables)
  }

  public func installDocset(
    forEntry entry: FeedEntry,
    isInstalledAsLatest: Bool,
    usingTarix: Bool
  ) -> AnyPublisher<InstallationProgress, Error> {
    return DocsetInstaller.shared.installDocset(forEntry: entry, usingTarix: usingTarix)
  }

  // MARK: - Uninstall

  public func uninstallDocset(forInstallation installation: DocsetInstallation) throws {
    try LibraryDatabase.shared.deleteDocsetInstallation(installation)
    try FileManager.default.removeItem(
      atPath: LocalFileSystem.docsetsAbsolutePath.appendingPathComponent(installation.id)
    )
  }

}
