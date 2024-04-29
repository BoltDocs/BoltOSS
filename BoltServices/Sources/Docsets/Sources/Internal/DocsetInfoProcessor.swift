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

import BoltRepository
import BoltTypes
import BoltUtils

typealias InfoDictionary = [String: Any]

enum DocsetInfoKey: String, CaseIterable {

  case bundleIdentifier = "CFBundleIdentifier"
  case bundleName = "CFBundleName"
  case bundleVersion = "CFBundleVersion"
  case platformFamily = "DocSetPlatformFamily"
  case nameShorteningFamily = "DashDocSetNameShorteningFamily"
  case docsetFamily = "DashDocSetFamily"

  case indexFilePath = "dashIndexFilePath"
  case isJavaScriptEnabled = "isJavaScriptEnabled"
  case fallbackURL = "DashDocSetFallbackURL"
  case playgroundURL = "DashDocSetPlayURL"

  case isDash = "isDashDocset"
  case blocksOnlineResources = "DashDocSetBlocksOnlineResources"

  case docsetKeyword = "DashDocSetKeyword"
  case pluginSchemeKeyword = "DashDocSetPluginKeyword"
  case webSearchKeyword = "DashWebSearchKeyword"

  case declaredInStyle = "DashDocSetDeclaredInStyle"
  case doNotCheckOnlineResources = "DashDocSetDoNotCheckOnlineResources"

  case publisherName = "DocSetPublisherName"
  case publisherIdentifier = "DocSetPublisherIdentifier"
  case feedName = "DocSetFeedName"
  case feedURL = "DocSetFeedURL"
  case shortVersionString = "CFBundleShortVersionString"
  case minimumXcodeVersion = "DocSetMinimumXcodeVersion"
  case humanReadableCopyright = "NSHumanReadableCopyright"
  case developmentRegion = "CFBundleDevelopmentRegion"
  case ftsEnabled = "DashDocSetDefaultFTSEnabled"

}

struct DocsetInfoProcessor: LoggerProvider {

  private static func isPlatformJavaScriptEnabled(forPlatformFamily platformFamily: DocsetInfo.PlatformFamily, generatorFamily: String?) -> Bool {
    let doxygenFamily = ["doxy", "doxygen"]
    return
      doxygenFamily.contains(platformFamily.rawValue) ||
      doxygenFamily.contains { $0 == generatorFamily }
  }

  static func migrateInfoDictionaryForWritten(_ dictionary: InfoDictionary, forFeedEntry entry: FeedEntry) -> InfoDictionary {
    var dictionary = dictionary

    // special care be taken special for platformFamily
    let platformFamilyStr = dictionary.getInfoValue(key: .platformFamily, type: String.self)
    if case .userContributed = entry.feed.repository {
      if !(platformFamilyStr ?? "").starts(with: "usercontrib") {
        // logger.warning("Missing or malformed `DocSetPlatformFamily`, overriding from feed metadata, id: \(entry.id).")
        dictionary[DocsetInfoKey.platformFamily.rawValue] = "usercontrib\(entry.feed.id)"
      }

      // keywords
      if dictionary.getInfoValue(key: .docsetKeyword, type: String.self) == nil {
        dictionary[DocsetInfoKey.docsetKeyword.rawValue] = entry.feed.id
      }
      if dictionary.getInfoValue(key: .pluginSchemeKeyword, type: String.self) == nil {
        dictionary[DocsetInfoKey.pluginSchemeKeyword.rawValue] = entry.feed.id
      }
      if dictionary.getInfoValue(key: .webSearchKeyword, type: String.self) == nil {
        dictionary[DocsetInfoKey.webSearchKeyword.rawValue] = entry.feed.id
      }
    }
    return dictionary
  }

  static func docsetInfo(forInfoDictionary infoDict: InfoDictionary) -> DocsetInfo {
    let name = infoDict.getInfoValue(key: .bundleIdentifier, type: String.self) ?? ""

    let displayName = infoDict.getInfoValue(key: .bundleName, type: String.self) ?? "Unknown"

    let generatorFamily = infoDict.getInfoValue(key: .docsetFamily, type: String.self)

    let nameShorteningFamily = infoDict.getInfoValue(key: .nameShorteningFamily, type: String.self) ?? generatorFamily

    let platformFamilyStr = infoDict.getInfoValue(key: .platformFamily, type: String.self) ?? "unknown"

    let platformFamily: DocsetInfo.PlatformFamily
    switch platformFamilyStr {
    case "cheatsheet":
      platformFamily = .cheatsheet
    case let str where str.starts(with: "usercontrib"):
      let family = str.replacingOccurrences(of: "usercontrib", with: "")
      platformFamily = .userContributed(name: family)
    default:
      platformFamily = .mainOrOther(name: platformFamilyStr)
    }

    let declaredInStyle = infoDict.getInfoValue(key: .declaredInStyle, type: Bool.self) ?? false

    var isJavaScriptEnabled = infoDict.getInfoValue(key: .isJavaScriptEnabled, type: Bool.self) ?? false

    isJavaScriptEnabled = isJavaScriptEnabled || isPlatformJavaScriptEnabled(forPlatformFamily: platformFamily, generatorFamily: generatorFamily)

    let fallbackURL: URL?
    if let fallbackURLString = infoDict.getInfoValue(key: .fallbackURL, type: String.self) {
      fallbackURL = URL(string: fallbackURLString)
    } else {
      fallbackURL = nil
    }

    let blocksOnlineResources = infoDict.getInfoValue(key: .blocksOnlineResources, type: Bool.self) ?? false

    let indexPagePath = infoDict.getInfoValue(key: .indexFilePath, type: String.self)

    let infoVersion = infoDict.getInfoValue(key: .bundleVersion, type: String.self) ?? "1.0.0"

    let isDash = infoDict.getInfoValue(key: .isDash, type: Bool.self) ?? false
    let format: DocsetInfo.Format = isDash ? .dash : .zDash

    let docsetKeyword = infoDict.getInfoValue(key: .docsetKeyword, type: String.self) ?? ""
    let pluginSchemeKeyword = infoDict.getInfoValue(key: .pluginSchemeKeyword, type: String.self) ?? docsetKeyword
    let webSearchKeyword = infoDict.getInfoValue(key: .webSearchKeyword, type: String.self) ?? docsetKeyword

    let keyword = DocsetInfo.Keyword(inAppSearch: docsetKeyword, pluginScheme: pluginSchemeKeyword, webSearch: webSearchKeyword)

    return DocsetInfo(
      bundleIdentifier: name,
      bundleVersion: infoVersion,
      bundleDisplayName: displayName,
      format: format,
      platformFamily: platformFamily,
      generatorFamily: generatorFamily,
      nameShorteningFamily: nameShorteningFamily,
      isJavaScriptEnabled: isJavaScriptEnabled,
      fallbackURL: fallbackURL,
      shouldBlockContents: blocksOnlineResources,
      declaredInStyle: declaredInStyle,
      indexPagePath: indexPagePath,
      keyword: keyword
    )
  }

}

private extension Dictionary where Key == String {

  func getInfoValue<T>(key: DocsetInfoKey, type: T.Type) -> T? {
    guard let value = self[key.rawValue] as? T else {
      return nil
    }
    return value
  }

}
