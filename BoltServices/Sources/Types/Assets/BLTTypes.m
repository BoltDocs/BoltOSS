//
// Copyright (C) 2025 Bolt Contributors
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

#import "include/BLTTypes.h"

@implementation BLTTypes

+ (NSBundle *)assetsBundle {
#if SWIFT_PACKAGE
  return SWIFTPM_MODULE_BUNDLE;
#else
  NSBundle *moduleBundle = [NSBundle bundleForClass:BLTTypes.class];
  NSString *resourceBundlePath = [moduleBundle pathForResource:@"BoltServices_BoltTypesAssets" ofType:@"bundle"];
  if ([resourceBundlePath length]) {
    NSBundle *resourceBundle = [NSBundle bundleWithURL:[NSURL fileURLWithPath:resourceBundlePath]];
    if (resourceBundle) {
      return resourceBundle;
    }
  }
  return moduleBundle;
#endif
}

@end
