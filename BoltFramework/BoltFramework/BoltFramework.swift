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

import BoltAppKitBridge
import BoltLibraryUI
import BoltModuleExports
import BoltServices
import BoltUIFoundation
import BoltURLSchemes
import BoltUtils

import Factory
import IssueReporting

public class BoltFramework: LoggerProvider {

  public static let shared = BoltFramework()

  private init() {
    ServicesModule.initialize()

    let _ = Container.shared.appearanceService()

    let _ = Container.shared.crashesService()
    let _ = Container.shared.distributionService()
    let _ = Container.shared.analyticsService()

    #if targetEnvironment(macCatalyst)
    Container.shared.appKitBridge.register {
      guard let appKitBridge = Self.loadAppKitBridgeFromBundle() else {
        reportIssue("failed to initialize appkit bridge bundle")
        return nil
      }
      return appKitBridge
    }

    let _ = Container.shared.appKitBridge()

    #endif

    Container.shared.schemeService().registerSchemeHandler(DashFeedSchemeHandler())
  }

  public func onReceiveBackgroundDownloadCompletionHandler(_ completionHandler: @escaping () -> Void) {
    Container.shared.downloadManager().setBackgroundDownloadCompletionHandler(completionHandler)
  }

#if targetEnvironment(macCatalyst)

  private static func loadAppKitBridgeFromBundle() -> AppKitBridgeProtocol? {
    guard let bundleURL = Bundle.main.builtInPlugInsURL?.appendingPathComponent("BoltAppKitBridgeRuntime.bundle") else {
      return nil
    }

    guard let bundle = Bundle(url: bundleURL) else {
      Self.logger.error("failed to initialize appkit bridge bundle at url: \(bundleURL)")
      return nil
    }

    do {
      try bundle.loadAndReturnError()
    } catch {
      Self.logger.error("failed to load appkit bridge bundle: \(bundle) at url: \(bundleURL), error: \(error)")
      return nil
    }

    guard
      let AppKitBridge = bundle.classNamed("BoltAppKitBridgeRuntime.AppKitBridge") as? AppKitBridgeProtocol.Type
    else {
      Self.logger.error("failed to load appkit bridge class at bundle: \(bundle) url: \(bundleURL)")
      return nil
    }

    // swiftlint:disable:next explicit_init
    return AppKitBridge.init()
  }

#endif

}
