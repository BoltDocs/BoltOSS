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
      "BoltBrowserUIResources",
      "BoltModuleExports",
      "BoltServices",
      "BoltUIFoundation",
    ],
    path: "./BoltBrowserUI",
    exclude: ["Assets", "Bundle+BoltBrowserUI.swift"],
    swiftSettings: [
      .unsafeFlags(["-warn-soft-deprecated"]),
      .swiftLanguageMode(.v5),
    ]
  ),
  .target(
    name: "BoltBrowserUIResources",
    path: "./BoltBrowserUI",
    sources: ["Bundle+BoltBrowserUI.swift"],
    resources: [
      .copy("./Assets/."),
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
      "BoltLibraryUIResources",
      "BoltModuleExports",
      "BoltServices",
      "BoltUIFoundation",
      "BoltUserGuideUI",
    ],
    path: "./BoltLibraryUI",
    exclude: ["Assets", "Tests"],
    swiftSettings: [
      .unsafeFlags(["-warn-soft-deprecated"]),
      .swiftLanguageMode(.v5),
    ]
  ),
  .target(
    name: "BoltLibraryUIResources",
    path: "./BoltLibraryUI/Assets",
    resources: [
      .process("Assets.xcassets"),
    ]
  ),
  .target(
    name: "BoltLookupUI",
    dependencies: [
      "SnapKit",
      "BoltBrowserUI",
      "BoltLookupUIResources",
      "BoltUIFoundation",
      "BoltModuleExports",
      "RoutableNavigation",
    ],
    path: "./BoltLookupUI",
    exclude: ["Bundle+BoltLookupUI.swift", "Scenes/LookupList/Cell/EntryCell.xib"],
    swiftSettings: [
      .unsafeFlags(["-warn-soft-deprecated"]),
      .swiftLanguageMode(.v5),
    ]
  ),
  .target(
    name: "BoltLookupUIResources",
    path: "./BoltLookupUI",
    sources: ["Bundle+BoltLookupUI.swift"],
    resources: [
      .process("Scenes/LookupList/Cell/EntryCell.xib"),
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
      "BoltUIFoundationResources",
    ],
    path: "./BoltUIFoundation",
    exclude: ["Assets"],
    swiftSettings: [
      .unsafeFlags(["-warn-soft-deprecated"]),
      .swiftLanguageMode(.v5),
    ]
  ),
  .target(
    name: "BoltUIFoundationResources",
    path: "./BoltUIFoundation/Assets",
    resources: [
      .process("Assets.xcassets"),
    ]
  ),
  .target(
    name: "BoltUserGuideUI",
    dependencies: [
      "BoltServices",
      "BoltUIFoundation",
      "BoltUserGuideUIResources",
    ],
    path: "./BoltUserGuideUI/Sources",
    swiftSettings: [.unsafeFlags(["-warn-soft-deprecated"])]
  ),
  .target(
    name: "BoltUserGuideUIResources",
    path: "./BoltUserGuideUI/Resources",
    resources: [
      .copy("./user-guides"),
    ]
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

let frameworkTargets: [Target] = {
  let dependencies: [Target.Dependency] = [
    "BoltAppKitBridge",
    "BoltFrameworkResources",
    "BoltUIFoundation",
    "BoltHomeUI",
    "BoltLookupUI",
    "BoltLibraryUI",
    "BoltPreferencesUI",
    "BoltUserGuideUI",
  ]

  return [
    .target(
      name: "BoltFramework",
      dependencies: dependencies,
      path: "./BoltFramework",
      exclude: ["Assets"],
      swiftSettings: [
        .unsafeFlags(["-warn-soft-deprecated"]),
        .swiftLanguageMode(.v5),
      ]
    ),
    .target(
      name: "BoltFrameworkResources",
      path: "./BoltFramework/Assets",
      resources: [
        .process("Assets.xcassets"),
      ]
    ),
  ]
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
  targets: libraryTargets + frameworkTargets + testTargets
)

// swiftlint:enable prefixed_toplevel_constant
