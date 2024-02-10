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

import RxCocoa
import RxSwift

public extension ObservableType where Element == Bool {

  func not() -> Observable<Bool> {
    return map(!)
  }

}

public extension SharedSequenceConvertibleType {

  func mapToVoid() -> SharedSequence<SharingStrategy, Void> {
    return map { _ in }
  }

}

public extension ObservableType {

  func catchErrorJustNever() -> Observable<Element> {
    return self.catch { _ in
      return Observable.never()
    }
  }

  func catchErrorJustComplete() -> Observable<Element> {
    return self.catch { _ in
      return Observable.empty()
    }
  }

  func asInfallibleOnErrorJustIgnore() -> Infallible<Element> {
    return asInfallible(onErrorFallbackTo: Infallible.never())
  }

  func asInfallibleOnErrorJustComplete() -> Infallible<Element> {
    return asInfallible(onErrorFallbackTo: .empty())
  }

  func asDriverOnErrorJustIgnore() -> Driver<Element> {
    return asDriver(onErrorDriveWith: .never())
  }

  func asDriverOnErrorJustComplete() -> Driver<Element> {
    return asDriver(onErrorDriveWith: .empty())
  }

  func mapToVoid() -> Observable<Void> {
    return map { _ in }
  }

}
