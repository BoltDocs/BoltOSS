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

import Foundation

/// - SeeAlso: https://github.com/microsoft/appcenter-sdk-apple/blob/5.0.4/AppCenter/AppCenter/Internals/Util/MSACUtility%2BEnvironment.m

public enum RuntimeEnvironment {

  case appStore
  case testFlight
  case simulator
  case adhoc
  case catalyst
  case other

  public static var currentAppEnvironment: Self {
  #if targetEnvironment(simulator)
    return .simulator
  #elseif targetEnvironment(macCatalyst)
    return .catalyst
  #elseif os(iOS)
    // MobileProvision profiles are a clear indicator for Ad-Hoc distribution.
    if self.hasEmbeddedMobileProvision {
      return .adhoc
    }
    /**
     * TestFlight is only supported from iOS 8 onwards and as our deployment target is iOS 8, we don't have to do any checks for
     * floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1).
     */
    if self.isAppStoreReceiptSandbox {
      return .testFlight
    }

    return .appStore
  #else
    return .other
  #endif
  }

  public static var isRunningTests: Bool {
    return ProcessInfo.processInfo.environment.keys.contains { $0.starts(with: "XCTest" ) }
  }

  static var hasEmbeddedMobileProvision: Bool {
    return Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil
  }

  static var isAppStoreReceiptSandbox: Bool {
  #if !targetEnvironment(simulator)
    return false
  #else
    if
      Bundle.main.responds(to: #selector(getter: Bundle.appStoreReceiptURL)),
      let appStoreReceiptURL = Bundle.main.appStoreReceiptURL
    {
      let appStoreReceiptLastComponent = appStoreReceiptURL.lastPathComponent
      let isSandboxReceipt = appStoreReceiptLastComponent == "sandboxReceipt"
      return isSandboxReceipt
    }
    return false
  #endif
  }

}
