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

import SwiftUI
import UIKit

import BoltLocalizations
import BoltServices
import BoltUIFoundation

struct PreferencesAboutView: View {

  var body: some View {
    List {
      Section(
        header:
          VStack(alignment: .center, spacing: 12) {
            let iconImage = Image(uiImage: InfoValues.iconImage ?? UIImage())
              .resizable()
            #if targetEnvironment(macCatalyst)
            iconImage
              .frame(width: 96, height: 96)
            #else
            iconImage
              .frame(width: 60, height: 60)
              .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            #endif
            VStack(spacing: 4) {
              Text("\(InfoValues.appDisplayName) - \(InfoValues.appVersion) (\(InfoValues.appBuildNumber))")
              #if !DEBUG
              Text("(\(InfoValues.appCommit))")
              #else
              Text("(Debug)")
              #endif
            }
          }
          .frame(maxWidth: .infinity)
          .padding(.bottom, 12)
          .textCase(.none)
      ) {
        NavigationLink("Preferences-About-acknowledgementsTitle".boltLocalized) {
          DeferredView {
            LicensePlistView()
              .navigationTitle("Preferences-About-acknowledgementsTitle".boltLocalized)
          }
        }
      }
      Section {
        NavigationLink("Preferences-About-contributeTitle".boltLocalized) {
          DeferredView {
            PreferencesContributionView()
          }
        }
      }
    }
    .navigationTitle("Preferences-About-title".boltLocalized)
    .navigationBarTitleDisplayMode(.inline)
  }

}
