#!/bin/sh

set -e
set -x

if ! [ "${CONFIGURATION}" == "Release" ]; then
  exit
fi

repo_path="${1:-.}"
plist_key="${2:-BoltOSSCommit}"

git=`sh /etc/profile; which git`

branch_name=`$git -C "$repo_path" symbolic-ref HEAD | sed -e 's,.*/\\(.*\\),\\1,'`
simple_branch_name=`$git -C "$repo_path" rev-parse --short HEAD`

commit_hash="$simple_branch_name"

plist="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

/usr/libexec/PlistBuddy -c "Set :$plist_key $commit_hash" "$plist"
