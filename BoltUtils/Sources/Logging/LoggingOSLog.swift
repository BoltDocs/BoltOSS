//
// Copyright (C) 2026 Bolt Contributors
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
//
// Original source under Apache-2.0 license:
// https://github.com/chrisaljoudi/swift-log-oslog/blob/1b2cb12c3ec2cdc171e1673a488dec1d40a69158/Sources/LoggingOSLog/LoggingOSLog.swift
//
// Modifications made by Bolt Contributors:
//   - Changes to the code style, logger category initialization and log style
//

import Foundation
import os

import Logging
// swiftlint:disable:next duplicate_imports
import struct Logging.Logger

public struct LoggingOSLog: LogHandler {

  public var logLevel: Logger.Level = .info
  public let label: String

  private let oslogger: OSLog

  public init(label: String) {
    self.label = label
    let subsystem = Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName
    self.oslogger = OSLog(subsystem: subsystem, category: label)
  }

  public init(label: String, log: OSLog) {
    self.label = label
    self.oslogger = log
  }

  // swiftlint:disable:next function_parameter_count
  public func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
    var combinedPrettyMetadata = prettyMetadata
    if let metadataOverride = metadata, !metadataOverride.isEmpty {
      combinedPrettyMetadata = prettify(
        self.metadata.merging(metadataOverride) {
          return $1
        }
      )
    }

    let messagePrefix = "\(file.lastPathComponent):\(line) [\(label)]"

    var formedMessage = "\(messagePrefix) \(message.description)"
    if let combinedPrettyMetadata = combinedPrettyMetadata {
      formedMessage += " -- " + combinedPrettyMetadata
    }

    os_log("%{public}@", log: oslogger, type: OSLogType.from(loggerLevel: level), formedMessage as NSString)
  }

  private var prettyMetadata: String?
  public var metadata = Logger.Metadata() {
    didSet {
      prettyMetadata = prettify(metadata)
    }
  }

  /// Add, remove, or change the logging metadata.
  /// - parameters:
  ///    - metadataKey: the key for the metadata item.
  public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
    get {
      return metadata[metadataKey]
    }
    set {
      metadata[metadataKey] = newValue
    }
  }

  private func prettify(_ metadata: Logger.Metadata) -> String? {
    if metadata.isEmpty {
      return nil
    }
    return metadata.map {
      "\($0)=\($1)"
    }
    .joined(separator: " ")
  }
}

private extension OSLogType {

  static func from(loggerLevel: Logger.Level) -> Self {
    switch loggerLevel {
    case .trace:
      /// `OSLog` doesn't have `trace`, so use `debug`
      return .debug
    case .debug:
      return .debug
    case .info:
      return .info
    case .notice:
      // https://developer.apple.com/documentation/os/logging/generating_log_messages_from_your_code
      // According to the documentation, `default` is `notice`.
      return .default
    case .warning:
      /// `OSLog` doesn't have `warning`, so use `info`
      return .info
    case .error:
      return .error
    case .critical:
      return .fault
    }
  }

}
