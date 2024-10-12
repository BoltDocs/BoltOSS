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

private struct DismissSheetModalEnvironmentKey: EnvironmentKey {
  static let defaultValue: DismissAction? = nil
}

public extension EnvironmentValues {
  var dismissSheetModal: DismissAction? {
    get { self[DismissSheetModalEnvironmentKey.self] }
    set { self[DismissSheetModalEnvironmentKey.self] = newValue }
  }
}

public struct SheetContainer<Content: View>: View {

  @Environment(\.dismiss)
  private var dismiss: DismissAction

  public init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }

  private let content: () -> Content

  public var body: some View {
    content()
      .environment(\.dismissSheetModal, dismiss)
  }
}
