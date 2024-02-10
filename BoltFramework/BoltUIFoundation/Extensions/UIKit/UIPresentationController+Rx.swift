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

import UIKit

import RxCocoa
import RxSwift

public extension Reactive where Base: UIPresentationController {

  var presentationTransitionWillBegin: ControlEvent<Void> {
    let source =
      self.methodInvoked(#selector(UIPresentationController.presentationTransitionWillBegin))
      .map { _ in return }
      return ControlEvent(events: source)
  }

  var presentationTransitionDidEnd: ControlEvent<Bool> {
    let source =
      self.methodInvoked(#selector(UIPresentationController.presentationTransitionDidEnd(_:)))
      .map { $0[1] as! Bool }
      return ControlEvent(events: source)
  }

  var dismissalTransitionWillBegin: ControlEvent<Void> {
    let source =
      self.methodInvoked(#selector(UIPresentationController.dismissalTransitionWillBegin))
      .map { _ in return }
      return ControlEvent(events: source)
  }

  var dismissalTransitionDidEnd: ControlEvent<Bool> {
    let source =
      self.methodInvoked(#selector(UIPresentationController.dismissalTransitionDidEnd(_:)))
      .map { $0[1] as! Bool }
      return ControlEvent(events: source)
  }

  var containerViewWillLayoutSubviews: ControlEvent<Void> {
    let source =
      self.methodInvoked(#selector(UIPresentationController.containerViewWillLayoutSubviews))
      .map { _ in return }
      return ControlEvent(events: source)
  }

  var containerViewDidLayoutSubviews: ControlEvent<Void> {
    let source =
      self.methodInvoked(#selector(UIPresentationController.containerViewDidLayoutSubviews))
      .map { _ in return }
      return ControlEvent(events: source)
  }

}
