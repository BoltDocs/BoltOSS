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

import BoltFramework
import BoltModuleExports
import BoltUtils

final class SceneDelegate: UIResponder, UIWindowSceneDelegate, LoggerProvider {

  var window: UIWindow?

  var sceneManager: SceneManager?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let window = self.window else {
      reportIssue("SceneDelegate should always have a root window!")
      return
    }

    #if targetEnvironment(macCatalyst)
    // https://developer.apple.com/documentation/uikit/mac_catalyst/removing_the_title_bar_in_your_mac_app_built_with_mac_catalyst
    if let windowScene = (scene as? UIWindowScene), let titlebar = windowScene.titlebar {
      titlebar.titleVisibility = .hidden
      titlebar.toolbar = nil
    }
    #endif

    sceneManager = SceneManager(window)
  }

  func sceneDidDisconnect(_ scene: UIScene) {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    checkForDocsetUpdatesIfNeeded()
  }

  func sceneWillResignActive(_ scene: UIScene) {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
  }

  func sceneWillEnterForeground(_ scene: UIScene) {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
  }

  func sceneDidEnterBackground(_ scene: UIScene) {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
  }

  // MARK: - Private

  private func checkForDocsetUpdatesIfNeeded() {
    let updateCheckingFrequency = UserDefaults.standard.updateCheckingFrequency
    let lastCheckForUpdates = UserDefaults.standard.lastCheckForUpdates

    guard updateCheckingFrequency > 0 else {
      Self.logger.info("skip docset update checking due to frequency set to never")
      return
    }

    let currentTimeInterval = Int(Date.now.timeIntervalSince1970)

    if currentTimeInterval - lastCheckForUpdates > updateCheckingFrequency {
      Self.logger.info("start checking for docset update, last check: \(lastCheckForUpdates)")
      UserDefaults.standard.lastCheckForUpdates = currentTimeInterval
      Task {
        let docsetUpdateChecker = Container.shared.docsetUpdateChecker()
        let entries = await docsetUpdateChecker.fetchDocsetUpdates(useCachedEntries: false)
        Self.logger.info("\(entries.count) updatable entries available")
      }
    }
  }

}

// MARK: - URL Scheme Handling

extension SceneDelegate {

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    Container.shared.schemeService().matchToHandle(withURLs: URLContexts.map { $0.url })
  }

}
