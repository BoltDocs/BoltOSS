#!/bin/sh

set -e
set -x

if ! [ "${CONFIGURATION}" == "Release" ]; then
  exit
fi

BASEDIR=$(dirname $0)

LICENSE_PLIST_PATH="$BASEDIR/../Thirdparty/LicensePlist"
LICENSE_PLIST_VERSION="3_27_2"

CONFIG_PATH=$1
if [ -z "$CONFIG_PATH" ]; then
  CONFIG_PATH=$LICENSE_PLIST_PATH/license_plist.yml
fi

RESOURCES_PATH=$2
if [ -z "$RESOURCES_PATH" ]; then
  RESOURCES_PATH="$BASEDIR/../$PRODUCT_NAME/Resources/LicensePlist"
fi

FAIL_IF_MISSING_LICENSE_FLAG=''
if [ "$CONFIGURATION" = "Release" ]; then
  FAIL_IF_MISSING_LICENSE_FLAG='--fail-if-missing-license'
fi

mkdir -p $RESOURCES_PATH

$LICENSE_PLIST_PATH/license-plist-$LICENSE_PLIST_VERSION \
--output-path $RESOURCES_PATH \
--prefix $PRODUCT_BUNDLE_IDENTIFIER.Licenses \
--config-path $CONFIG_PATH \
--suppress-opening-directory \
$FAIL_IF_MISSING_LICENSE_FLAG \

rsync -avh --delete $RESOURCES_PATH/$PRODUCT_BUNDLE_IDENTIFIER.Licenses $BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH
rsync -avh --delete $RESOURCES_PATH/$PRODUCT_BUNDLE_IDENTIFIER.Licenses.plist $BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH
