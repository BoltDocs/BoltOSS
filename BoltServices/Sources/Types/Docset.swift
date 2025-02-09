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

import BoltUtils

public struct DocsetInfo: Sendable {

  public enum Format: Sendable {
    case dash, zDash
  }

  public enum PlatformFamily: Sendable, RawRepresentable {
    public typealias RawValue = String

    case mainOrOther(name: String)
    case cheatsheet
    case userContributed(name: String)

    public init?(rawValue: String) {
      switch rawValue {
      case "cheatsheet":
        self = .cheatsheet
      case let str where str.starts(with: "usercontrib"):
        let family = str.replacingOccurrences(of: "usercontrib", with: "")
        self = .userContributed(name: family)
      default:
        self = .mainOrOther(name: rawValue)
      }
    }

    public var rawValue: String {
      switch self {
      case .cheatsheet:
        return "cheatsheet"
      case let .userContributed(name: name):
        return "usercontrib\(name)"
      case let .mainOrOther(name):
        return name
      }
    }

    public var name: String {
      switch self {
      case .cheatsheet:
        return "cheatsheet"
      case let .userContributed(name: name):
        return name
      case let .mainOrOther(name):
        return name
      }
    }
  }

  // - SeeAlso: dash-ios/DHUserRepo.mL308
  public struct Keyword: Sendable {

    public let inAppSearch: String

    // for dash-plugin:// schemes
    // - SeeAlso: https://kapeli.com/dash_plugins
    public let pluginScheme: String

    public let webSearch: String

    public init(
      inAppSearch: String,
      pluginScheme: String,
      webSearch: String
    ) {
      self.inAppSearch = inAppSearch
      self.pluginScheme = pluginScheme
      self.webSearch = webSearch
    }
  }

  public let bundleIdentifier: String
  public let bundleVersion: String
  public let bundleDisplayName: String

  public let format: Self.Format
  public let generatorFamily: String?
  public let platformFamily: Self.PlatformFamily
  public let nameShorteningFamily: String?

  public let isJavaScriptEnabled: Bool
  public let fallbackURL: URL?
  public let shouldBlockContents: Bool

  public let declaredInStyle: Bool

  public let indexPagePath: String?

  public let keyword: Self.Keyword

  public init(
    bundleIdentifier: String,
    bundleVersion: String,
    bundleDisplayName: String,
    format: Format,
    platformFamily: PlatformFamily,
    generatorFamily: String?,
    nameShorteningFamily: String?,
    isJavaScriptEnabled: Bool,
    fallbackURL: URL?,
    shouldBlockContents: Bool,
    declaredInStyle: Bool,
    indexPagePath: String?,
    keyword: Keyword
  ) {
    self.bundleIdentifier = bundleIdentifier
    self.bundleVersion = bundleVersion
    self.bundleDisplayName = bundleDisplayName
    self.format = format
    self.platformFamily = platformFamily
    self.generatorFamily = generatorFamily
    self.nameShorteningFamily = nameShorteningFamily
    self.isJavaScriptEnabled = isJavaScriptEnabled
    self.fallbackURL = fallbackURL
    self.shouldBlockContents = shouldBlockContents
    self.declaredInStyle = declaredInStyle
    self.indexPagePath = indexPagePath
    self.keyword = keyword
  }

}

public struct Docset: Sendable {

  public let installation: DocsetInstallation
  public let path: String
  public let icon: EntryIcon

  private let docsetInfo: DocsetInfo

  // MARK: Docset Info Properties

  public var displayName: String { docsetInfo.bundleDisplayName }

  public var generatorFamily: String? { docsetInfo.generatorFamily }
  public var platformFamily: DocsetInfo.PlatformFamily { docsetInfo.platformFamily }

  public var isJavaScriptEnabled: Bool { docsetInfo.isJavaScriptEnabled }
  public var fallbackURL: URL? { docsetInfo.fallbackURL }

  public var indexPagePath: String? { docsetInfo.indexPagePath }
  public var keyword: DocsetInfo.Keyword { docsetInfo.keyword }

  public init(
    installation: DocsetInstallation,
    path: String,
    docsetInfo: DocsetInfo,
    icon: EntryIcon
  ) {
    self.installation = installation
    self.path = path
    self.docsetInfo = docsetInfo
    self.icon = icon
  }

}

extension Docset: LibraryRecord {

  public var uuid: UUID {
    return installation.uuid
  }

  public var uuidString: String {
    return installation.uuidString
  }

  public var name: String {
    return installation.name
  }

  public var version: String {
    return installation.version
  }

  public var installedAsLatestVersion: Bool {
    return installation.installedAsLatestVersion
  }

  public var repository: RepositoryIdentifier {
    return installation.repository
  }

  public var identifier: String {
    return installation.identifier
  }

}

extension Docset: EntryIconProvider {

  public static let defaultIconImage: PlatformImage = {
    #if os(iOS)
    PlatformImage(
      systemName: "books.vertical",
      withConfiguration: PlatformImage.SymbolConfiguration(
        pointSize: 16
      )
    )!
    #else
    PlatformImage(
      systemSymbolName: "books.vertical",
      accessibilityDescription: nil
    )!
    .withSymbolConfiguration(
      PlatformImage.SymbolConfiguration(
        pointSize: 16,
        weight: .regular
      )
    )!
    #endif
  }()

}

extension Docset: Hashable {

  public static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.installation.uuid == rhs.installation.uuid
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(installation.uuid)
  }

}
