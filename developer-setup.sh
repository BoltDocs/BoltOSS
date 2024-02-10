#!/bin/bash

echo This script will create a SharedXcodeSettings folder and a DeveloperSettings.xcconfig file.
echo
echo We need to ask you a few questions first.
echo
read -p "Press enter to get started."

echo 1. What is your Developer Team ID? You can get this from developer.apple.com.
read devTeamID

echo 2. What is your organisation identifier? e.g. com.developername.
read devOrgName

echo Creating SharedXcodeSettings Folder...
mkdir -p ../SharedXcodeSettings

echo Creating DeveloperSettings.xcconfig...

cat <<file >>../SharedXcodeSettings/DeveloperSettings.xcconfig
DEVELOPMENT_TEAM = $devTeamID
ORGANIZATION_IDENTIFIER = $devOrgName
file

echo Done!
