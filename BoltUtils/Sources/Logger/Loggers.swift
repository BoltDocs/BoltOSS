//
// Copyright (C) 2023 Bolt Contributors
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
import struct os.Logger

public protocol LoggerProvider {

  static var loggerCategory: String { get }

  static var logger: Logger { get }

}

public extension LoggerProvider {

  static var loggerCategory: String {
    return String(describing: Self.self)
  }

  static var logger: Logger {
    return Loggers.forCategory(loggerCategory)
  }

}

public actor Loggers {

  private static var loggers: [String: Logger] = [:]

  public static func forCategory(_ category: String) -> Logger {
    if let logger = loggers[category] {
      return logger
    }
    let newLogger = Logger(category: category)
    loggers[category] = newLogger
    return newLogger
  }

}
