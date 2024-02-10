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

// - SeeAlso: RxWebKit: a1d52c6245a6ce3ec326db0715445aeaa093cf01

import Foundation
import WebKit

import RxCocoa
import RxSwift

extension Reactive where Base: WKWebView {

  /**
   Reactive wrapper for `title` property
   */
  var title: Driver<String?> {
    return self.observeWeakly(String.self, "title")
      .asDriverOnErrorJustIgnore()
  }

  /**
   Reactive wrapper for `loading` property.
   */
  var loading: Observable<Bool> {
    return self.observeWeakly(Bool.self, "loading")
      .map { $0 ?? false }
  }

  /**
   Reactive wrapper for `estimatedProgress` property.
   */
  var estimatedProgressObservable: Driver<Double> {
    return self.observeWeakly(Double.self, "estimatedProgress")
      .map { $0 ?? 0.0 }
      .asDriverOnErrorJustIgnore()
  }

  /**
   Reactive wrapper for `url` property.
   */
  var currentURL: Driver<URL?> {
    return self.observeWeakly(URL.self, "URL")
      .asDriverOnErrorJustIgnore()
  }

  /**
   Reactive wrapper for `canGoBack` property.
   */
  var canGoBack: Driver<Bool> {
    return self.observeWeakly(Bool.self, "canGoBack")
      .map { $0 ?? false }
      .asDriverOnErrorJustIgnore()
  }

  /**
   Reactive wrapper for `canGoForward` property.
   */
  var canGoForward: Driver<Bool> {
    return self.observeWeakly(Bool.self, "canGoForward")
      .map { $0 ?? false }
      .asDriverOnErrorJustIgnore()
  }

  /// Reactive wrapper for `evaluateJavaScript(_:completionHandler:)` method.
  ///
  /// - Parameter javaScriptString: The JavaScript string to evaluate.
  /// - Returns: Observable sequence of result of the script evaluation.
  func evaluateJavaScript(_ javaScriptString: String) -> Observable<Any?> {
    return Observable.create { [weak base] observer in
      base?.evaluateJavaScript(javaScriptString) { value, error in
        if let error = error {
          observer.onError(error)
        } else {
          observer.onNext(value)
          observer.onCompleted()
        }
      }
      return Disposables.create()
    }
  }

}
