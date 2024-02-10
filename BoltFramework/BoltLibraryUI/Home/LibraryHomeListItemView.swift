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

import BoltUIFoundation

struct LibraryHomeListItemView: View {

  let itemModel: LibraryHomeListViewModel.Section.Item

  var body: some View {
    HStack(alignment: .center, spacing: 16) {
      Image(uiImage: itemModel.icon.platformImage!)
        .resizable()
        .frame(width: 32, height: 32)
        .foregroundColor(.accentColor)
      VStack(alignment: .leading, spacing: 2) {
        Text(itemModel.name)
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(Color.primary)
          .lineLimit(1)
        Text(itemModel.description)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundColor(Color.secondary)
          .lineLimit(2)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding([.top, .bottom], 10)
  }

}
