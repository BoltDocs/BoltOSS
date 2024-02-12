// swift-tools-version:5.9

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

let products: [Product] = [
  .library(name: "BoltServices", targets: ["BoltServices"]),
]

struct Dependencies {

  static var BoltUtilsTesting: PackageDescription.Target.Dependency {
    .product(name: "BoltUtilsTesting", package: "BoltUtils")
  }

  static var GzipSwift: PackageDescription.Target.Dependency {
    .product(name: "Gzip", package: "GzipSwift")
  }

  static var GRDB: PackageDescription.Target.Dependency {
    .product(name: "GRDB", package: "GRDB.swift")
  }

}

// all modules imported explicitly should be contained in `dependencies`

let moduleTargets: [Target] = [
  .target(
    name: "BoltArchives",
    dependencies: [Dependencies.GRDB, Dependencies.GzipSwift, "CombineExt", "SWCompressionTAR", "BoltUtils"],
    path: "./Sources/Archives/Sources"
  ),
  .target(
    name: "BoltNetworking",
    dependencies: ["Alamofire", "SwiftyJSON", "SwiftyXMLParser", "BoltTypes"],
    path: "./Sources/Networking/Sources"
  ),
  .target(
    name: "BoltDatabase",
    dependencies: [Dependencies.GRDB, "CombineExt", "BoltTypes"],
    path: "./Sources/Database"
  ),
  .target(
    name: "BoltDocsets",
    dependencies: [Dependencies.GRDB, "BoltArchives", "BoltDatabase", "BoltRepository", "BoltURLSchemes", "BoltUtils"],
    path: "./Sources/Docsets/Sources"
  ),
  .target(
    name: "BoltRepository",
    dependencies: ["SwiftyJSON", "BoltDatabase", "BoltNetworking", "BoltTypes", "BoltURLSchemes", "BoltUtils"],
    path: "./Sources/Repository/Sources"
  ),
  .target(
    name: "BoltTypes",
    dependencies: ["BoltUtils", "Factory"],
    path: "./Sources/Types",
    resources: [.process("Resources")]
  ),
  .target(
    name: "BoltSearch",
    dependencies: [Dependencies.GRDB, "BoltDocsets", "BoltTypes"],
    path: "./Sources/Search"
  ),
  .target(
    name: "BoltURLSchemes",
    dependencies: ["BoltTypes"],
    path: "./Sources/URLSchemes"
  ),
  .target(
    name: "BoltServices",
    dependencies: [
      "BoltUtils",
      "BoltArchives",
      "BoltDatabase",
      "BoltDocsets",
      "BoltRepository",
      "BoltRxSwift",
      "BoltSearch",
      "BoltTypes",
      "BoltURLSchemes",
    ],
    path: "./Sources",
    sources: ["Application", "BoltServicesModule.swift", "BoltServicesExports.swift"]
  ),
]

let testingUtils: [Target] = [
  .target(
    name: "BoltTestingUtils",
    dependencies: [Dependencies.BoltUtilsTesting, "BoltTypes"],
    path: "./Sources/Testing"
  ),
  .target(
    name: "BoltNetworkingTestStubs",
    dependencies: ["BoltUtils", "BoltNetworking"],
    path: "./Sources/Networking/TestStubs",
    resources: [
      .copy("./TestResources"),
    ]
  ),
]

let testTargets: [Target] = [
  .testTarget(name: "BoltArchivesTests", dependencies: ["BoltTestingUtils", "BoltArchives"], path: "./Sources/Archives/Tests", resources: [.copy("./TestResources")]),
  .testTarget(name: "BoltNetworkingTests", dependencies: ["BoltNetworking"], path: "./Sources/Networking/Tests"),
  .testTarget(
    name: "BoltRepositoryTests",
    dependencies: ["BoltRepository", "BoltTestingUtils", "BoltNetworkingTestStubs"],
    path: "./Sources/Repository/Tests"
  ),
  .testTarget(
    name: "BoltDocsetsTests",
    dependencies: ["BoltDocsets", "BoltTestingUtils"],
    path: "./Sources/Docsets/",
    sources: [
      "./Tests"
    ],
    resources: [
      .copy("./TestResources"),
    ]
  ),
]

let dependencies: [Package.Dependency] = [
  .package(name: "BoltUtils", path: "../BoltUtils"),
  .package(name: "BoltRxSwift", path: "../BoltRxSwift"),
  .package(url: "https://github.com/hmlongco/Factory.git", revision: "2.3.1"),
  .package(url: "https://github.com/BoltDocs/SWCompressionTAR.git", revision: "4.8.5"),
  .package(url: "https://github.com/CombineCommunity/CombineExt.git", revision: "1.8.1"),
  .package(url: "https://github.com/BoltDocs/GzipSwift.git", revision: "6.0.1"),
  .package(url: "https://github.com/groue/GRDB.swift.git", revision: "v6.24.2"),
  .package(url: "https://github.com/Alamofire/Alamofire.git", revision: "5.8.1"),
  .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", revision: "5.0.1"),
  .package(url: "https://github.com/yahoojapan/SwiftyXMLParser.git", revision: "5.6.0"),
]

let package = Package(
  name: "BoltServices",
  platforms: [
    .iOS(.v16),
    .macCatalyst(.v17),
    .macOS(.v14),
  ],
  products: products,
  dependencies: dependencies,
  targets: moduleTargets + testingUtils + testTargets
)

// swiftlint:enable prefixed_toplevel_constant
