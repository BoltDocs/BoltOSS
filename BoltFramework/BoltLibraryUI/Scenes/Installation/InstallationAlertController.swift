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

import UIKit

import RxCocoa
import RxSwift

import BoltArchives
import BoltRxSwift
import BoltServices
import BoltUIFoundation
import BoltUtils

private extension ErrorMessageEntity {

  static let installationSuccess = ErrorMessageEntity(description: "Install success", level: .success)
  static let installationFailed = ErrorMessageEntity(description: "Install failed", level: .error)

  static let tarixNotFound = ErrorMessageEntity(description: "Archive index file not found", level: .warning)
  static let docsetNotFound = ErrorMessageEntity(description: "Docset file not found", level: .warning)

}

@MainActor
final class InstallationAlert: HasDisposeBag {

  private let installationObservable: Observable<InstallationProgress>
  private let alertController: UIAlertController

  init(installationObservable: Observable<InstallationProgress>) {
    self.installationObservable = installationObservable
    self.alertController = UIAlertController(title: "Installation", message: "", preferredStyle: .alert)
  }

  func startInstall() {
    GlobalUI.presentAlertController(alertController, configure: nil, completion: nil)
    installationObservable
      .observe(on: MainScheduler.instance)
      .subscribe(
        with: alertController,
        onNext: { owner, progress in
          switch progress {
          case let .extracting(progress):
            owner.message = "Extracting files: \(progress)"
          }
        }, onError: { _, error in
          Self.handleInstallationError(error)
        }, onCompleted: { _ in
          GlobalUI.showMessageToast(withErrorMessage: ErrorMessage(entity: .installationSuccess, nestedError: nil))
        }, onDisposed: { _ in
          GlobalUI.dismissCurrentAlertController(completion: nil)
        }
      )
      .disposed(by: alertController.disposeBag)
  }

  private static func handleInstallationError(_ error: Error) {
    var errorType: ErrorMessageEntity = .installationFailed
    if let error = error as? DocsetUnarchiverError {
      if case .tarixNotFound = error {
        errorType = .tarixNotFound
      } else if case .docsetNotFound = error {
        errorType = .docsetNotFound
      }
    }
    GlobalUI.showMessageToast(withErrorMessage: ErrorMessage(entity: errorType, nestedError: error))
  }

}

extension UIAlertController: @retroactive HasDisposeBag { }
