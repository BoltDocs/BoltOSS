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

import Factory

public enum LibraryInstallationQueryResult: Hashable {

  case docset(_: Docset)
  case broken(_: DocsetInstallation)

  public var record: LibraryRecord {
    switch self {
    case let .docset(docset):
      return docset
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

public extension Container {

  var libraryDocsetsManager: Factory<LibraryDocsetsManager> { self { LibraryDocsetsManagerImp() }.cached }

}

public protocol LibraryDocsetsManager {

  var installedDocsets: [LibraryInstallationQueryResult] { get }
  var installedDocsetsPublisher: AnyPublisher<[LibraryInstallationQueryResult], Never> { get }

  var installedRecords: [LibraryRecord] { get }
  var installedRecordsPublisher: AnyPublisher<[LibraryRecord], Never> { get }

  func installDocset(
    forEntry entry: FeedEntry,
    isInstalledAsLatest: Bool,
    usingTarix: Bool
  ) -> AnyPublisher<InstallationProgress, Error>

  func uninstallDocset(forRecord record: LibraryRecord) throws

  func updateInstalledDocsetsOrder(_ records: [LibraryRecord]) throws

}

final class LibraryDocsetsManagerImp: LibraryDocsetsManager, LoggerProvider {

  private var cancellables = Set<AnyCancellable>()

  private lazy var _installedDocsets = CurrentValueSubject<[LibraryInstallationQueryResult], Never>([])

  var installedDocsets: [LibraryInstallationQueryResult] {
    return _installedDocsets.value
  }

  var installedDocsetsPublisher: AnyPublisher<[LibraryInstallationQueryResult], Never> {
    return _installedDocsets
      .eraseToAnyPublisher()
  }

  var installedRecords: [LibraryRecord] {
    return _installedDocsets.value.map { result in
      switch result {
      case let .docset(docset):
        return docset
      case let .broken(installation):
        return installation
      }
    }
  }

  var installedRecordsPublisher: AnyPublisher<[LibraryRecord], Never> {
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

  init() {
    LibraryDatabase.shared.allDocsetInstallations
      .map { array in
        array.compactMap { installation -> LibraryInstallationQueryResult in
          if let docset = LibraryDocsetsFileSystemBridge.docset(withInstallation: installation) {
            return .docset(docset)
          } else {
            return .broken(installation)
          }
        }
      }
      .assign(to: \.value, on: _installedDocsets)
      .store(in: &cancellables)
  }

  func installDocset(
    forEntry entry: FeedEntry,
    isInstalledAsLatest: Bool,
    usingTarix: Bool
  ) -> AnyPublisher<InstallationProgress, Error> {
    return DocsetInstaller.shared.installDocset(forEntry: entry, usingTarix: usingTarix)
  }

  // MARK: - Uninstall

  func uninstallDocset(forRecord record: LibraryRecord) throws {
    try LibraryDatabase.shared.deleteDocsetInstallation(withUUID: record.uuid)
    try FileManager.default.removeItem(
      atPath: LocalFileSystem.docsetsAbsolutePath.appendingPathComponent(record.uuidString)
    )
  }

  func updateInstalledDocsetsOrder(_ records: [LibraryRecord]) throws {
    try LibraryDatabase.shared.updateDocsetInstallationOrder(records)
  }

}
