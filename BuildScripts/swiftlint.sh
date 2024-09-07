#!/bin/sh

BASEDIR=$(dirname $0)

SWIFTLINT_PATH="$BASEDIR/../Thirdparty/SwiftLint"
SWIFTLINT="0_56_2"

$SWIFTLINT_PATH/swiftlint-$SWIFTLINT ${@:1}
