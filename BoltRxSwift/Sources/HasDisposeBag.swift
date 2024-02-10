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
import ObjectiveC

import ObjectAssociationHelper
import RxSwift

private var disposeBagContext = "DisposeBag"

/// Each HasDisposeBag offers a unique RxSwift DisposeBag instance
public protocol HasDisposeBag: AnyObject {

  /// A unique RxSwift DisposeBag instance
  var disposeBag: DisposeBag { get set }

}

extension HasDisposeBag {

  func synchronizedBag<T>( _ action: () -> T) -> T {
    objc_sync_enter(self)
    let result = action()
    objc_sync_exit(self)
    return result
  }

  public var disposeBag: DisposeBag {
    get {
      return synchronizedBag {
        ObjectAssociationHelper.associatedObject(self, key: &disposeBagContext, initializer: DisposeBag())
      }
    }
    set {
      synchronizedBag {
        ObjectAssociationHelper.associateObject(self, key: &disposeBagContext, value: newValue)
      }
    }
  }

}
