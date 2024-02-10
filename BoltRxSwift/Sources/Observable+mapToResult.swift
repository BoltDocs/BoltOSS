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

import RxSwift

public extension ObservableType {

  func mapToResult() -> Infallible<Result<Element, Error>> {
    return self
      .map { Result<Element, Error>.success($0) }
      .catch { error in
        return Observable.just(Result<Element, Error>.failure(error))
      }
      .asInfallibleOnErrorJustIgnore()
  }

}
