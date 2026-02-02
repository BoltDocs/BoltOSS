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

import UIKit

import Factory
import IssueReporting

import BoltAppKitBridge
import BoltFramework
import BoltModuleExports
import BoltUtils

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate, LoggerProvider {

  lazy var boltFramework = BoltFramework.shared

  var window: UIWindow?

  func application(
    _ application: UIApplication,
    willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? // swiftlint:disable:this discouraged_optional_collection
  ) -> Bool {
    return true
  }

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? // swiftlint:disable:this discouraged_optional_collection
  ) -> Bool {
    #if targetEnvironment(macCatalyst)
    if let appKitBridge = loadAppKitBridgeFromBundle() {
      Container.shared.appKitBridge.register { appKitBridge }
    } else {
      reportIssue("failed to initialize appkit bridge bundle")
    }
    #endif
    let _ = boltFramework
    return true
  }

#if targetEnvironment(macCatalyst)

  private func loadAppKitBridgeFromBundle() -> AppKitBridgeProtocol? {
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

extension AppDelegate {

  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(
      name: "Default Configuration",
      sessionRole: connectingSceneSession.role
    )
  }

  func application(
    _ application: UIApplication,
    didDiscardSceneSessions sceneSessions: Set<UISceneSession>
  ) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }

}

// MARK: - Background Downloading

extension AppDelegate {

  func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
  ) {
    boltFramework.onReceiveBackgroundDownloadCompletionHandler(completionHandler)
  }

}
