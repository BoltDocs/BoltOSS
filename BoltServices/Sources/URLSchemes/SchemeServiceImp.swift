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

import Factory

public final class SchemeServiceImp: SchemeService {

  private var schemeHandlers = [SchemeHandler]()

  public func registerSchemeHandler(_ schemeHandler: SchemeHandler) {
    schemeHandlers.append(schemeHandler)
  }

  public func matchToHandle(withURL url: URL) -> Bool {
    return matchToHandle(withURLs: [url])
  }

  public func matchToHandle(withURLs urls: [URL]) -> Bool {
    return schemeHandlers.contains { handler in
      return urls.contains { url in
        return handler.matchToHandle(withURL: url)
      }
    }
  }

}

public extension Container {

  var schemeService: Factory<SchemeService> { self { SchemeServiceImp() }.cached }

}
