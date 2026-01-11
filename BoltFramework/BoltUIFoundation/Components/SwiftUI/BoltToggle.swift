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

import SwiftUI

public struct BoltToggle<Label>: View where Label: View {

  public private(set) var isOn: Binding<Bool>
  public private(set) var isEnabled: Bool

  public private(set) var label: Label

  public init(
    isOn: Binding<Bool>,
    isEnabled: Bool = true,
    @ViewBuilder label: () -> Label
  ) {
    self.isOn = isOn
    self.isEnabled = isEnabled
    self.label = label()
  }

  public var body: some View {
    Toggle(isOn: isOn) {
      label
    }
    .disabled(!isEnabled)
    .tint(.accentColor)
  }

}

public extension BoltToggle where Label == Text {

  init<S>(_ title: S, isOn: Binding<Bool>, isEnabled: Bool = true) where S: StringProtocol {
    self.init(isOn: isOn, isEnabled: isEnabled) {
      Text(title)
    }
  }

}
