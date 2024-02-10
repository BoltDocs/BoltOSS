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

public extension ErrorMessageEntity {

  static let fetchEntriesFailed = ErrorMessageEntity(description: "Failed to fetch available versions")
  static let docsetAlreadyDownloaded = ErrorMessageEntity(
    description: "The docset is already being downloaded",
    level: .warning
  )
  static let docsetAlreadyInstalling = ErrorMessageEntity(
    description: "Docset with same version is already installing",
    level: .warning
  )
  static let failedToInstall = ErrorMessageEntity(description: "Failed to install docset")
  static let noInstallationStatusMatched = ErrorMessageEntity(description: "No matched installation task")
  static let failedToUninstall = ErrorMessageEntity(description: "Docset uninstallation failed")
  static let noMatchedIndexToUninstall = ErrorMessageEntity(description: "No matched docset to uninstall")
  static let noInstallationToCancel = ErrorMessageEntity(description: "Specified task is already cancelled")

  static let failedToImportCustomFeed = ErrorMessageEntity(description: "Failed to import custom feed")

}
