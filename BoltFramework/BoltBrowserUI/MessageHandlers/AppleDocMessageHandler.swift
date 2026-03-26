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

import Foundation
import WebKit

import BoltUtils

protocol AppleDocMessageHandlerDelegate: AnyObject {

  func appleDocMessageHandlerDidRender(_: AppleDocMessageHandler)
  func appleDocMessageHandlerDidRequestCodeColors(_: AppleDocMessageHandler)

}

final class AppleDocMessageHandler: NSObject, WKScriptMessageHandler, LoggerProvider {

  enum EventType: String {
    case rendered
    case requestCodeColors
  }

  let name = "bridge"

  weak var delegate: AppleDocMessageHandlerDelegate?

  init(delegate: AppleDocMessageHandlerDelegate) {
    self.delegate = delegate
    super.init()
  }

  func userContentController(
    _ userContentController: WKUserContentController,
    didReceive message: WKScriptMessage
  ) {
    guard let data = message.body as? [String: Any] else {
      Self.logger.error("[AppleDocMessageHandler] invalid message.body: \(String(describing: message.body))")
      return
    }

    guard let type = data["type"] as? String else {
      Self.logger.error("[AppleDocMessageHandler] type not found in message.body: \(String(describing: message.body))")
      return
    }

    guard let eventType = EventType(rawValue: type) else {
      Self.logger.warning("[AppleDocMessageHandler] unknown event type: \(type)")
      return
    }

    switch eventType {
    case .rendered:
      delegate?.appleDocMessageHandlerDidRender(self)
    case .requestCodeColors:
      delegate?.appleDocMessageHandlerDidRequestCodeColors(self)
    }
  }

}
