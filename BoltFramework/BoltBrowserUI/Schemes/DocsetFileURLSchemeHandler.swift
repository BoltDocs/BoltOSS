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
import WebKit

import BoltArchives
import BoltServices
import BoltUtils

enum WebErrors: Error {
  case RequestFailedError
}

// - SeeAlso: https://stackoverflow.com/questions/69216563/how-to-enable-wkurlschemehandler-to-do-work-off-main-thread

public class TarixURLSchemeHandler: NSObject, WKURLSchemeHandler {

  static let queue = DispatchQueue(label: "app.BoltDocs.Bolt.TarixURLSchemeHandler", qos: .userInitiated)

  private var stoppedTaskURLs: [URLRequest] = []

  public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
    let request = urlSchemeTask.request
    guard
      let url = urlSchemeTask.request.url,
      url.scheme == DocsetFileURLScheme.scheme,
      let scheme = DocsetFileURLScheme(url: url)
    else {
      urlSchemeTask.didFailWithError(WebErrors.RequestFailedError)
      return
    }

    let response = URLResponse(url: url, mimeType: url.mimeType(), expectedContentLength: -1, textEncodingName: nil)

    if let data = Self.loadTarix(fromScheme: scheme) {
      postResponse(to: urlSchemeTask, response: response)
      postResponse(to: urlSchemeTask, data: data)
      postFinished(to: urlSchemeTask)
    } else if let data = Self.loadFile(fromScheme: scheme) {
      postResponse(to: urlSchemeTask, response: response)
      postResponse(to: urlSchemeTask, data: data)
      postFinished(to: urlSchemeTask)
    } else {
      postFailed(to: urlSchemeTask, error: WebErrors.RequestFailedError)
    }

    // remove the task from the list of stopped tasks (if it is there)
    // since we're done with it anyway
    stoppedTaskURLs = stoppedTaskURLs.filter { $0 != request }
  }

  public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
    if !hasTaskStopped(urlSchemeTask) {
      stoppedTaskURLs.append(urlSchemeTask.request)
    }
  }

  // MARK: - Private

  private func hasTaskStopped(_ urlSchemeTask: WKURLSchemeTask) -> Bool {
    return stoppedTaskURLs.contains { $0 == urlSchemeTask.request }
  }

  private func postResponse(to urlSchemeTask: WKURLSchemeTask, response: URLResponse) {
    post(to: urlSchemeTask) { urlSchemeTask.didReceive(response) }
  }

  private func postResponse(to urlSchemeTask: WKURLSchemeTask, data: Data) {
    post(to: urlSchemeTask) { urlSchemeTask.didReceive(data) }
  }

  private func postFinished(to urlSchemeTask: WKURLSchemeTask) {
    post(to: urlSchemeTask) { urlSchemeTask.didFinish() }
  }

  private func postFailed(to urlSchemeTask: WKURLSchemeTask, error: Error) {
    post(to: urlSchemeTask) { urlSchemeTask.didFailWithError(error) }
  }

  private func post(to urlSchemeTask: WKURLSchemeTask, action: @escaping () -> Void) {
    if hasTaskStopped(urlSchemeTask) == false {
      action()
    }
  }

}

private extension TarixURLSchemeHandler {

  static func loadTarix(fromScheme scheme: DocsetFileURLScheme) -> Data? {
    let docsetPath = LocalFileSystem.docsetsAbsolutePath
      .appendingPathComponent(scheme.docsetUUID)
      .appendingPathComponent(scheme.docsetFileName)

    let tarFilePath = docsetPath.appendingPathComponent("/Contents/Resources/tarix.tgz")
    let tarixDBPath = docsetPath.appendingPathComponent("/Contents/Resources/tarixIndex.db")

    if !FileManager.default.fileExists(atPath: tarFilePath) {
      return nil
    }

    let result = UncheckedSendableContainer<Data>()

    let group = DispatchGroup()
    group.enter()

    Task {
      let res = try? await TarixUnarchiver.dataFromIndexedTar(
        tarFilePath: tarFilePath,
        tarixDBPath: tarixDBPath,
        atPath: "\(scheme.docsetFileName)/Contents/Resources/Documents\(scheme.path)",
        usingQueue: queue
      )
      result.set(val: res?.1)
      group.leave()
    }

    group.wait()

    return result.value
  }

  static func loadFile(fromScheme scheme: DocsetFileURLScheme) -> Data? {
    let docsetPath = LocalFileSystem.docsetsAbsolutePath
      .appendingPathComponent(scheme.docsetUUID)
      .appendingPathComponent(scheme.docsetFileName)
    let filePath = "\(docsetPath)/Contents/Resources/Documents\(scheme.path)"

    guard FileManager.default.fileExists(atPath: filePath) else {
      return nil
    }
    return try? Data(contentsOf: URL(fileURLWithPath: filePath))
  }

}
