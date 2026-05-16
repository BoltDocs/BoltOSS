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

import SwiftUI

import BoltUIFoundation
import BoltUserGuide

private struct UserGuideSheetModifier: ViewModifier {

  let location: UserGuideLocation

  @Binding var isPresented: Bool

  func body(content: Content) -> some View {
    content
      .sheet(isPresented: $isPresented) {
        SheetContainer {
          UserGuideView(location: location)
        }
      }
  }

}

private struct UserGuideSheetURLModifier: ViewModifier {

  @Binding var location: UserGuideLocation?

  func body(content: Content) -> some View {
    content
      .sheet(item: $location) { location in
        SheetContainer {
          UserGuideView(location: location)
        }
      }
  }

}

public extension View {

  func userGuideSheet(location: UserGuideLocation, isPresented: Binding<Bool>) -> some View {
    modifier(UserGuideSheetModifier(location: location, isPresented: isPresented))
  }

  func userGuideSheet(location: Binding<UserGuideLocation?>) -> some View {
    modifier(UserGuideSheetURLModifier(location: location))
  }

}
