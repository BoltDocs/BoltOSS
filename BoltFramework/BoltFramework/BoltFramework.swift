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

import BoltLibraryUI
import BoltModuleExports
import BoltServices
import BoltUIFoundation
import BoltURLSchemes
import BoltUtils

import Factory

public class BoltFramework {

  public static let shared = BoltFramework()

  private init() {
    ServicesModule.initialize()

    let _ = Container.shared.appearanceService()

    let _ = Container.shared.crashesService()
    let _ = Container.shared.crashesService()
    let _ = Container.shared.analyticsService()

    Container.shared.schemeService().registerSchemeHandler(DashFeedSchemeHandler())
  }

  public func onReceiveBackgroundDownloadCompletionHandler(_ completionHandler: @escaping () -> Void) {
    Container.shared.downloadManager().setBackgroundDownloadCompletionHandler(completionHandler)
  }

}
