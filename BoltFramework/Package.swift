// swift-tools-version:6.0

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

// swiftlint:disable prefixed_toplevel_constant

import PackageDescription

let libraryTargets: [Target] = [
  .target(
    name: "BoltBrowserUI",
    dependencies: [
      "SnapKit",
      "BoltModuleExports",
      "BoltServices",
      "BoltUIFoundation",
    ],
    path: "./BoltBrowserUI",
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
  .target(
    name: "BoltHomeUI",
    dependencies: [
      "SnapKit",
      "BoltModuleExports",
      "BoltServices",
      "BoltUIFoundation",
    ],
    path: "./BoltHomeUI",
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
  .target(
    name: "BoltModuleExports",
    dependencies: [
      "BoltRxSwift",
      "BoltServices",
    ],
    path: "./BoltModuleExports"
  ),
  .target(
    name: "BoltLibraryUI",
    dependencies: [
      "BoltModuleExports",
      "BoltServices",
      "BoltUIFoundation",
    ],
    path: "./BoltLibraryUI",
    resources: [
      .process("./Assets"),
    ],
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
  .target(
    name: "BoltLookupUI",
    dependencies: [
      "SnapKit",
      "BoltUIFoundation",
      "BoltModuleExports",
      "RoutableNavigation",
    ],
    path: "./BoltLookupUI",
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
  .target(
    name: "BoltPreferencesUI",
    dependencies: [
      "BoltModuleExports",
      "BoltServices",
      "BoltUIFoundation",
      "LicensePlistViewController",
      "BetterSafariView",
    ],
    path: "./BoltPreferencesUI",
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
  .target(
    name: "BoltUIFoundation",
    dependencies: [
      "BoltRxSwift",
      .product(name: "Overture", package: "swift-overture"),
      "GSMessages",
      "BoltServices",
      "BoltLocalizations",
    ],
    path: "./BoltUIFoundation",
    resources: [
      .process("./Assets"),
    ],
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
]

let frameworkTarget: Target = {
  let dependencies: [Target.Dependency] = [
    "BoltUIFoundation",
    "BoltBrowserUI",
    "BoltHomeUI",
    "BoltLookupUI",
    "BoltLibraryUI",
    "BoltPreferencesUI",
  ]

  return .target(
    name: "BoltFramework",
    dependencies: dependencies,
    path: "./BoltFramework",
    resources: [
      .process("./Assets"),
    ],
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  )
}()

let package = Package(
  name: "BoltFramework",
  platforms: [
    .iOS(.v17),
    .macCatalyst(.v18),
  ],
  products: [
    .library(
      name: "BoltFramework",
      type: .dynamic,
      targets: ["BoltFramework"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/SnapKit/SnapKit.git", exact: "5.7.1"),
    .package(url: "https://github.com/yhirano/LicensePlistViewController.git", exact: "2.3.0"),
    .package(url: "https://github.com/stleamist/BetterSafariView.git", exact: "2.4.2"),
    .package(url: "https://github.com/wxxsw/GSMessages.git", revision: "88d895a"),
    .package(url: "https://github.com/pointfreeco/swift-overture.git", revision: "0.5.0"),
    .package(url: "https://github.com/BoltDocs/RoutableNavigation.git", revision: "5fa1eb3"),
    .package(path: "../BoltRxSwift"),
    .package(path: "../BoltLocalizations"),
    .package(path: "./BoltServices"),
  ],
  targets: libraryTargets + [frameworkTarget]
)

// swiftlint:enable prefixed_toplevel_constant
