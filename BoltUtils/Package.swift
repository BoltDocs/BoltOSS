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
  name: "BoltUtils",
  platforms: [
    .iOS(.v17),
    .macCatalyst(.v18),
    .macOS(.v15),
  ],
  products: [
    .library(
      name: "BoltUtils",
      targets: ["BoltUtils"]
    ),
    .library(
      name: "BoltUtilsTesting",
      targets: ["BoltUtilsTesting"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-issue-reporting.git", revision: "1.4.2")
  ],
  targets: [
    .target(
      name: "BoltUtils",
      dependencies: [
        .product(name: "IssueReporting", package: "swift-issue-reporting"),
      ],
      path: "./Sources",
      exclude: ["Testing"]
    ),
    .target(
      name: "BoltUtilsTesting",
      path: "./Sources/Testing"
    ),
  ]
)

// swiftlint:enable prefixed_toplevel_constant
