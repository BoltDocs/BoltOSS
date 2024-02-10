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

import struct os.Logger

import RxCocoa
import RxSwift

import BoltUtils

public extension ObservableType {

  var logger: Logger {
    return Loggers.forCategory(String(describing: Self.self))
  }

  func debugLogging(_ tag: String) -> Observable<Element> {
    #if DEBUG
    return self.do { obj in
      logger.debug("[\(tag)] onNext: \(String(describing: obj))")
    } onError: { error in
      logger.debug("[\(tag)] onError: \(String(describing: error))")
    } onCompleted: {
      logger.debug("[\(tag)] onCompleted")
    } onSubscribe: {
      logger.debug("[\(tag)] onSubscribed")
    } onDispose: {
      logger.debug("[\(tag)] onDisposed")
    }
    #else
    return self.asObservable()
    #endif
  }

}

public extension SharedSequenceConvertibleType {

  var logger: Logger {
    return Loggers.forCategory(String(describing: Self.self))
  }

  func debugLogging(_ tag: String) -> SharedSequence<SharingStrategy, Element> {
    #if DEBUG
    return self.do { obj in
      logger.debug("[\(tag)] onNext: \(String(describing: obj))")
    } onCompleted: {
      logger.debug("[\(tag)] onCompleted")
    } onSubscribe: {
      logger.debug("[\(tag)] onSubscribed")
    } onDispose: {
      logger.debug("[\(tag)] onDisposed")
    }
    #else
    return self.asSharedSequence()
    #endif
  }

}
