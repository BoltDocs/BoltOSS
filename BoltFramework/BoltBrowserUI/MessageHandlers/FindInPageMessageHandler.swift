//
// Copyright (C) 2025 Bolt Contributors
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
import WebKit

import BoltUtils

protocol FindInPageMessageHandlerDelegate: AnyObject {

  func findInPageHelper(_: FindInPageMessageHandler, didUpdateCurrentResult: Int)
  func findInPageHelper(_: FindInPageMessageHandler, didUpdateTotalResults: Int)

}

final class FindInPageMessageHandler: NSObject, WKScriptMessageHandler, LoggerProvider {

  let name = "findInPageHandler"

  weak var delegate: FindInPageMessageHandlerDelegate?

  init(delegate: FindInPageMessageHandlerDelegate) {
    self.delegate = delegate
  }

  func userContentController(
    _ userContentController: WKUserContentController,
    didReceive message: WKScriptMessage
  ) {
    guard let data = message.body as? [String: Int] else {
      Self.logger.error("Invalid data message body in FindInPageHelper: \(String(describing: message.body))")
      return
    }

    if let currentResult = data["currentResult"] {
      delegate?.findInPageHelper(self, didUpdateCurrentResult: currentResult)
    }

    if let totalResults = data["totalResults"] {
      delegate?.findInPageHelper(self, didUpdateTotalResults: totalResults)
    }
  }

}
