# BoltOSS

Bolt is an offline documentation browser inspired by [Dash](https://kapeli.com/dash), dedicatedly built for iOS and iPadOS.

This repository hosts the open-source code that Bolt builds upon.

## Releases

This project is in the early development process and the official release will be available soon on AppStore.

[As with the consent from Kapeli](https://blog.kapeli.com/dash-for-ios-android-windows-or-linux), to be able to download Dash docsets, you should get Bolt from AppStore when it's available. For platforms other than iOS and iPadOS, check out [Dash](https://kapeli.com/dash) or [Zeal](https://github.com/zealdocs/zeal) or [Velocity](https://velocity.silverlakesoftware.com) instead.

Releases would be tagged or branched but no binary products would be uploaded.

## Liquid Glass

Liquid Glass is temporarily disabled due to preview test failures. Adapting to the OS 26 UI and its features is planned, but not prioritized until the core functionalities are properly implemented.

## Build instructions

We support building for up to 2 recent major versions of iOS and iPadOS and the most recent major version of Mac Catalyst, so currently it would be built with iOS 18, iPadOS 18, and Mac Catalyst 26 (macOS 26).

Mac Catalyst builds are only for easier development and testing, so only major issues would be solved.

Only the latest non-beta release of Xcode would be supported. Build with the latest Xcode 26 if you encounter any issues.

To checkout and build, use the following commands:

```sh
mkdir Bolt
git clone git@github.com:BoltDocs/BoltOSS.git Bolt
cd Bolt
git submodule update --init --recursive
sh developer-setup.sh
open Bolt.xcodeproj
```

## License

This software is licensed under the terms of the Apache License Version 2.0 (Apache-2.0). Full text of the license is available in the [LICENSE](LICENSE) file and [online](https://www.apache.org/licenses/LICENSE-2.0).
