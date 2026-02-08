//
// Copyright (C) 2026 Bolt Contributors
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

import AppKit
import Foundation
import UniformTypeIdentifiers

#if canImport(BoltAppKitBridge)
import BoltAppKitBridge
#endif

public final class AppKitBridge: NSObject, AppKitBridgeProtocol {

  public func showOpenPanel(
    allowedContentTypes: [UTType],
    canChooseFiles: Bool,
    canChooseDirectories: Bool,
    allowsMultipleSelection: Bool
  ) -> [URL]? { // swiftlint:disable:this discouraged_optional_collection
    let openPanel = NSOpenPanel()
    openPanel.canChooseFiles = canChooseFiles
    openPanel.canChooseDirectories = canChooseDirectories
    openPanel.allowsMultipleSelection = allowsMultipleSelection
    openPanel.allowedContentTypes = allowedContentTypes

    let response = openPanel.runModal()
    if response == .OK {
      return openPanel.urls
    }

    return nil
  }

}
