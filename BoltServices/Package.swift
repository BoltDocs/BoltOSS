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

  static var Overture: PackageDescription.Target.Dependency {
    .product(name: "Overture", package: "swift-overture")
  }

  static var UUIDShortener: PackageDescription.Target.Dependency {
    .product(name: "UUIDShortener", package: "uuid-shortener")
  }

}

// all modules imported explicitly should be contained in `dependencies`

let moduleTargets: [Target] = [
  .target(
    name: "BoltArchives",
    dependencies: [Dependencies.GRDB, Dependencies.GzipSwift, Dependencies.UUIDShortener, "BoltCombineExtensions", "SWCompressionTAR", "BoltTypes", "BoltUtils"],
    path: "./Sources/Archives/Sources",
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
  .target(
    name: "BoltNetworking",
    dependencies: ["Alamofire", "SwiftyJSON", "SwiftyXMLParser", "BoltTypes"],
    path: "./Sources/Networking/Sources",
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
  .target(
    name: "BoltDatabase",
    dependencies: [Dependencies.GRDB, "BoltCombineExtensions", "BoltTypes"],
    path: "./Sources/Database/Sources",
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
  .target(
    name: "BoltDocsets",
    dependencies: [Dependencies.GRDB, Dependencies.Overture, "BoltArchives", "BoltDatabase", "BoltRepository", "BoltURLSchemes", "BoltUtils"],
    path: "./Sources/Docsets/Sources",
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
  .target(
    name: "BoltRepository",
    dependencies: ["SwiftyJSON", "BoltDatabase", "BoltNetworking", "BoltTypes", "BoltURLSchemes", "BoltUtils"],
    path: "./Sources/Repository/Sources",
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
  .target(
    name: "BoltTypes",
    dependencies: ["BoltUtils", "Factory", "SwiftyJSON"],
    path: "./Sources/Types",
    resources: [.process("Resources")],
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
  .target(
    name: "BoltSearch",
    dependencies: [Dependencies.GRDB, Dependencies.Overture, "BoltCombineExtensions", "BoltDocsets", "BoltRxSwift", "BoltTypes"],
    path: "./Sources/Search/Sources",
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
  .target(
    name: "BoltURLSchemes",
    dependencies: ["BoltTypes"],
    path: "./Sources/URLSchemes",
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
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
    path: "./Sources/BoltServices",
    swiftSettings: [
      .swiftLanguageMode(.v5),
    ]
  ),
]

let testingUtils: [Target] = [
  .target(
    name: "BoltTestingUtils",
    dependencies: [Dependencies.BoltUtilsTesting, "BoltTypes"],
    path: "./Sources/Testing",
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
  .target(
    name: "BoltNetworkingTestStubs",
    dependencies: ["BoltUtils", "BoltNetworking"],
    path: "./Sources/Networking/TestStubs",
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
]

let testTargets: [Target] = [
  .testTarget(name: "BoltArchivesTests", dependencies: ["BoltTestingUtils", "BoltArchives"], path: "./Sources/Archives/Tests", resources: [.copy("./TestResources")]),
  .testTarget(
    name: "BoltDatabaseTests",
    dependencies: [Dependencies.GRDB, "BoltDatabase"],
    path: "./Sources/Database/Tests"
  ),
  .testTarget(name: "BoltNetworkingTests", dependencies: ["BoltNetworking"], path: "./Sources/Networking/Tests"),
  .testTarget(
    name: "BoltRepositoryTests",
    dependencies: ["BoltRepository", "BoltTestingUtils", "BoltNetworkingTestStubs"],
    path: "./Sources/Repository/Tests",
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
  .testTarget(
    name: "BoltDocsetsTests",
    dependencies: ["BoltDocsets", "BoltSearch", "BoltTestingUtils"],
    path: "./Sources/Docsets/",
    sources: [
      "./Tests"
    ],
    resources: [
      .copy("./TestResources"),
    ],
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
  .testTarget(
    name: "BoltSearchTests",
    dependencies: ["BoltSearch", "BoltTestingUtils"],
    path: "./Sources/Search",
    sources: [
      "./Tests"
    ],
    resources: [
      .copy("./TestResources"),
    ],
    swiftSettings: [
      .swiftLanguageMode(.v5)
    ]
  ),
]

let dependencies: [Package.Dependency] = [
  .package(name: "BoltUtils", path: "../BoltUtils"),
  .package(name: "BoltCombineExtensions", path: "../BoltCombineExtensions"),
  .package(name: "BoltRxSwift", path: "../BoltRxSwift"),
  .package(url: "https://github.com/hmlongco/Factory.git", revision: "2.4.3"),
  .package(url: "https://github.com/BoltDocs/SWCompressionTAR.git", revision: "4.8.6"),
  .package(url: "https://github.com/BoltDocs/GzipSwift.git", revision: "6.1.0"),
  .package(url: "https://github.com/groue/GRDB.swift.git", revision: "v6.29.3"),
  .package(url: "https://github.com/Alamofire/Alamofire.git", revision: "5.10.2"),
  .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", revision: "5.0.2"),
  .package(url: "https://github.com/yahoojapan/SwiftyXMLParser.git", revision: "5.6.0"),
  .package(url: "https://github.com/pointfreeco/swift-overture.git", revision: "0.5.0"),
  .package(url: "https://github.com/Dean151/uuid-shortener", revision: "v1.0.0"),
]

let package = Package(
  name: "BoltServices",
  platforms: [
    .iOS(.v17),
    .macCatalyst(.v18),
    .macOS(.v15),
  ],
  products: products,
  dependencies: dependencies,
  targets: moduleTargets + testingUtils + testTargets
)

// swiftlint:enable prefixed_toplevel_constant
