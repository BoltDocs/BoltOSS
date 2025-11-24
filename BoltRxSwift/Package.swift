// swift-tools-version:6.2
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
  name: "BoltRxSwift",
  platforms: [
    .iOS(.v18),
    .macCatalyst(.v26),
    .macOS(.v26),
  ],
  products: [
    .library(
      name: "BoltRxSwift",
      targets: ["BoltRxSwift"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", revision: "6.8.0"),
    .package(url: "https://github.com/CombineCommunity/RxCombine.git", revision: "2.0.1"),
    .package(url: "https://github.com/BoltDocs/ObjectAssociationHelper.git", revision: "1.0.0"),
    .package(name: "BoltUtils", path: "../BoltUtils"),
  ],
  targets: [
    .target(
      name: "BoltRxSwift",
      dependencies: [
        "ObjectAssociationHelper",
        .product(name: "RxSwift", package: "RxSwift"),
        .product(name: "RxCocoa", package: "RxSwift"),
        .product(name: "RxCombine", package: "RxCombine"),
        .product(name: "BoltUtils", package: "BoltUtils"),
      ],
      path: "./Sources"
    ),
  ]
)

// swiftlint:enable prefixed_toplevel_constant
