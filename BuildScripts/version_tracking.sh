#!/bin/sh

set -x

if ! [ "${CONFIGURATION}" == "Release" ]; then
  exit
fi

git=`sh /etc/profile; which git`

branch_name=`$git symbolic-ref HEAD | sed -e 's,.*/\\(.*\\),\\1,'`
simple_branch_name=`$git rev-parse --short HEAD`

commit_hash="$simple_branch_name"

plist="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

/usr/libexec/PlistBuddy -c "Set :BoltCommit $commit_hash" "$plist"
