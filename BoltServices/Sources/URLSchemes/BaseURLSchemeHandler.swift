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

import IssueReporting

public enum URLSchemeHandlerError: Error {
  case requestFailed
}

// - SeeAlso: https://stackoverflow.com/questions/69216563/how-to-enable-wkurlschemehandler-to-do-work-off-main-thread

open class BaseURLSchemeHandler<URLScheme>: NSObject, WKURLSchemeHandler {

  private var stoppedRequests: [URLRequest] = []

  public final func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
    let request = urlSchemeTask.request

    guard let url = urlSchemeTask.request.url, let scheme = parseScheme(from: url) else {
      urlSchemeTask.didFailWithError(URLSchemeHandlerError.requestFailed)
      return
    }

    Task.detached(priority: .userInitiated) { [weak self] in
      guard let self else {
        return
      }

      let response = URLResponse(url: url, mimeType: url.mimeType(), expectedContentLength: -1, textEncodingName: nil)

      if let data = await loadData(for: scheme) {
        await postResponse(to: urlSchemeTask, response: response)
        await postResponse(to: urlSchemeTask, data: data)
        await postFinished(to: urlSchemeTask)
      } else {
        await postFailed(to: urlSchemeTask, error: URLSchemeHandlerError.requestFailed)
      }
    }

    // remove the task from the list of stopped tasks (if it is there)
    // since we're done with it anyway
    stoppedRequests = stoppedRequests.filter { $0 != request }
  }

  public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
    if !isTaskStopped(urlSchemeTask) {
      stoppedRequests.append(urlSchemeTask.request)
    }
  }

  open func parseScheme(from url: URL) -> URLScheme? {
    reportIssue("Subclasses must override parseScheme(from:)")
    return nil
  }

  // swiftlint:disable:next async_without_await
  open func loadData(for scheme: URLScheme) async -> Data? {
    reportIssue("Subclasses must override loadData(for:)")
    return nil
  }

  // MARK: - Private

  private func isTaskStopped(_ urlSchemeTask: WKURLSchemeTask) -> Bool {
    return stoppedRequests.contains { $0 == urlSchemeTask.request }
  }

  private nonisolated func postResponse(to urlSchemeTask: WKURLSchemeTask, response: URLResponse) async {
    await post(to: urlSchemeTask) { urlSchemeTask.didReceive(response) }
  }

  private nonisolated func postResponse(to urlSchemeTask: WKURLSchemeTask, data: Data) async {
    await post(to: urlSchemeTask) { urlSchemeTask.didReceive(data) }
  }

  private nonisolated func postFinished(to urlSchemeTask: WKURLSchemeTask) async {
    await post(to: urlSchemeTask) { urlSchemeTask.didFinish() }
  }

  private nonisolated func postFailed(to urlSchemeTask: WKURLSchemeTask, error: Error) async {
    await post(to: urlSchemeTask) { urlSchemeTask.didFailWithError(error) }
  }

  private nonisolated func post(to urlSchemeTask: WKURLSchemeTask, action: @escaping () -> Void) async {
    if await isTaskStopped(urlSchemeTask) == false {
      action()
    }
  }

}
