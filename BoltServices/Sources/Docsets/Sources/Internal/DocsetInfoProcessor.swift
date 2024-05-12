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

import Factory

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

protocol DocsetInfoProcessor {

  func registerDocsetInfoProcessor(_ docsetInfoProcessor: RepoDocsetInfoProcessor, forIdentifier identifier: RepositoryIdentifier)

  func processForInstallation(withInfoDictionary dictionary: InfoDictionary, forFeedEntry entry: FeedEntry) -> InfoDictionary

  func docsetInfo(forInfoDictionary infoDict: InfoDictionary) -> DocsetInfo

}

extension Container {

  var docsetInfoProcessor: Factory<DocsetInfoProcessor> {
    self {
      return DocsetInfoProcessorImp()
    }
    .cached
  }

}

final class DocsetInfoProcessorImp: DocsetInfoProcessor, LoggerProvider {

  private var repoProcessors = [RepositoryIdentifier: RepoDocsetInfoProcessor]()

  func registerDocsetInfoProcessor(
    _ docsetInfoProcessor: RepoDocsetInfoProcessor,
    forIdentifier identifier: RepositoryIdentifier
  ) {
    repoProcessors[identifier] = docsetInfoProcessor
  }

  private static func isPlatformJavaScriptEnabled(forPlatformFamily platformFamily: DocsetInfo.PlatformFamily, generatorFamily: String?) -> Bool {
    let doxygenFamily = ["doxy", "doxygen"]
    return
      doxygenFamily.contains(platformFamily.rawValue) ||
      doxygenFamily.contains { $0 == generatorFamily }
  }

  func processForInstallation(withInfoDictionary dictionary: InfoDictionary, forFeedEntry entry: FeedEntry) -> InfoDictionary {
    var dictionary = dictionary

    if let repoProcessor = repoProcessors[entry.feed.repository] {
      dictionary = repoProcessor.processInfoDictionaryBeforeInstallation(forFeedEntry: entry, dictionary)
    }
    return dictionary
  }

  func docsetInfo(forInfoDictionary infoDict: InfoDictionary) -> DocsetInfo {
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

    isJavaScriptEnabled = isJavaScriptEnabled || Self.isPlatformJavaScriptEnabled(forPlatformFamily: platformFamily, generatorFamily: generatorFamily)

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

extension Dictionary where Key == String {

  func getInfoValue<T>(key: DocsetInfoKey, type: T.Type) -> T? {
    guard let value = self[key.rawValue] as? T else {
      return nil
    }
    return value
  }

}
