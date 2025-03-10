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

let package = Package(
  name: "BoltCombineExtensions",
  platforms: [
    .iOS(.v17),
    .macCatalyst(.v18),
    .macOS(.v15),
  ],
  products: [
    .library(
      name: "BoltCombineExtensions",
      targets: ["BoltCombineExtensions"]
    ),
  ],
  dependencies: [
    .package(name: "BoltUtils", path: "../BoltUtils"),
    .package(url: "https://github.com/CombineCommunity/CombineExt.git", revision: "1.8.1"),
  ],
  targets: [
    .target(
      name: "BoltCombineExtensions",
      dependencies: [
        "CombineExt",
        "BoltUtils",
      ],
      path: "./Sources"
    ),
  ]
)

// swiftlint:enable prefixed_toplevel_constant
