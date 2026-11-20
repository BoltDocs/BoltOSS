// swift-tools-version:6.4

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
    name: "BoltAppKitBridge",
    dependencies: [
      "Factory",
    ],
    path: "./BoltAppKitBridge",
    swiftSettings: [.unsafeFlags(["-warn-soft-deprecated"])]
  ),
  .target(
    name: "BoltBrowserUI",
    dependencies: [
      "SnapKit",
      "BoltAppleDocumentation",
      "BoltModuleExports",
      "BoltServices",
      "BoltUIFoundation",
    ],
    path: "./BoltBrowserUI",
    resources: [
      .copy("./Assets/."),
    ],
    swiftSettings: [
      .unsafeFlags(["-warn-soft-deprecated"]),
      .swiftLanguageMode(.v5),
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
      .unsafeFlags(["-warn-soft-deprecated"]),
      .swiftLanguageMode(.v5),
    ]
  ),
  .target(
    name: "BoltModuleExports",
    dependencies: [
      "BoltRxSwift",
      "BoltServices",
    ],
    path: "./BoltModuleExports",
    swiftSettings: [.unsafeFlags(["-warn-soft-deprecated"])]
  ),
  .target(
    name: "BoltLibraryUI",
    dependencies: [
      "BoltAppKitBridge",
      "BoltModuleExports",
      "BoltServices",
      "BoltUIFoundation",
      "BoltUserGuideUI",
    ],
    path: "./BoltLibraryUI",
    exclude: ["Tests"],
    resources: [
      .process("./Assets"),
    ],
    swiftSettings: [
      .unsafeFlags(["-warn-soft-deprecated"]),
      .swiftLanguageMode(.v5),
    ]
  ),
  .target(
    name: "BoltLookupUI",
    dependencies: [
      "SnapKit",
      "BoltBrowserUI",
      "BoltUIFoundation",
      "BoltModuleExports",
      "RoutableNavigation",
    ],
    path: "./BoltLookupUI",
    swiftSettings: [
      .unsafeFlags(["-warn-soft-deprecated"]),
      .swiftLanguageMode(.v5),
    ]
  ),
  .target(
    name: "BoltPreferencesUI",
    dependencies: [
      "BoltModuleExports",
      "BoltServices",
      "BoltUIFoundation",
      "LicensePlistViewController",
    ],
    path: "./BoltPreferencesUI",
    swiftSettings: [
      .unsafeFlags(["-warn-soft-deprecated"]),
      .swiftLanguageMode(.v5),
    ]
  ),
  .target(
    name: "BoltUIFoundation",
    dependencies: [
      "BoltRxSwift",
      "BetterSafariView",
      .product(name: "Overture", package: "BoltUtils"),
      "GSMessages",
      "BoltServices",
      "BoltLocalizations",
    ],
    path: "./BoltUIFoundation",
    resources: [
      .process("./Assets"),
    ],
    swiftSettings: [
      .unsafeFlags(["-warn-soft-deprecated"]),
      .swiftLanguageMode(.v5),
    ]
  ),
  .target(
    name: "BoltUserGuideUI",
    dependencies: [
      "BoltServices",
      "BoltUIFoundation",
    ],
    path: "./BoltUserGuideUI",
    resources: [
      .copy("./Resources/user-guides"),
    ],
    swiftSettings: [.unsafeFlags(["-warn-soft-deprecated"])]
  ),
]

let testTargets: [Target] = [
  .testTarget(
    name: "BoltLibraryUITests",
    dependencies: ["BoltLibraryUI", "BoltServices"],
    path: "./BoltLibraryUI/Tests",
    swiftSettings: [.unsafeFlags(["-warn-soft-deprecated"])]
  ),
]

let frameworkTarget: Target = {
  let dependencies: [Target.Dependency] = [
    "BoltAppKitBridge",
    "BoltUIFoundation",
    "BoltHomeUI",
    "BoltLookupUI",
    "BoltLibraryUI",
    "BoltPreferencesUI",
    "BoltUserGuideUI",
  ]

  return .target(
    name: "BoltFramework",
    dependencies: dependencies,
    path: "./BoltFramework",
    resources: [
      .process("./Assets"),
    ],
    swiftSettings: [
      .unsafeFlags(["-warn-soft-deprecated"]),
      .swiftLanguageMode(.v5),
    ]
  )
}()

let package = Package(
  name: "BoltFramework",
  platforms: [
    .iOS(.v26),
    .macCatalyst(.v27),
    .macOS(.v27),
  ],
  products: [
    .library(
      name: "BoltFramework",
      type: .dynamic,
      targets: ["BoltFramework"]
    ),
    .library(
      name: "BoltAppKitBridge",
      type: .static,
      targets: ["BoltAppKitBridge"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/hmlongco/Factory.git", revision: "2.4.3"),
    .package(url: "https://github.com/SnapKit/SnapKit.git", exact: "5.7.1"),
    .package(url: "https://github.com/yhirano/LicensePlistViewController.git", exact: "2.3.0"),
    .package(url: "https://github.com/stleamist/BetterSafariView.git", exact: "2.4.2"),
    .package(url: "https://github.com/wxxsw/GSMessages.git", revision: "88d895a"),
    .package(url: "https://github.com/BoltDocs/RoutableNavigation.git", revision: "9a2507d"),
    .package(path: "../BoltAppleDocumentation"),
    .package(path: "../BoltRxSwift"),
    .package(path: "../BoltLocalizations"),
    .package(path: "../BoltServices"),
    .package(path: "../BoltUtils"),
  ],
  targets: libraryTargets + [frameworkTarget] + testTargets
)

// swiftlint:enable prefixed_toplevel_constant
