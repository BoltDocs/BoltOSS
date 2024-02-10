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

import BoltTypes

import Factory

public protocol ResourceLocationResolver {

  func url(forResourceLocation: ResourceLocation) -> URL?

}

public protocol ResourceLocationResolvers {

  func addResolver(_: ResourceLocationResolver)

  func url(forResourceLocation: ResourceLocation) -> URL?

}

public extension Container {

  var resourceLocationResolvers: Factory<ResourceLocationResolvers> {
    self {
      let resolversImp = ResourceLocationResolversImp()
      resolversImp.addResolver(URLResourceLocationResolver())
      return resolversImp
    }
    .cached
  }

}

public final class ResourceLocationResolversImp: ResourceLocationResolvers {

  private var resolvers = [ResourceLocationResolver]()

  public func addResolver(_ resolver: ResourceLocationResolver) {
    resolvers.append(resolver)
  }

  public func url(forResourceLocation location: ResourceLocation) -> URL? {
    return resolvers.firstMap {
      $0.url(forResourceLocation: location)
    }
  }

}

public struct URLResourceLocationResolver: ResourceLocationResolver {

  public func url(forResourceLocation resourceLocation: ResourceLocation) -> URL? {
    if let resourceLocation = resourceLocation as? URLResourceLocation {
      return resourceLocation.URL
    }
    return nil
  }

}
