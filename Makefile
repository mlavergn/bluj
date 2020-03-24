###############################################
#
# Makefile
#
###############################################

PROJECT := BluJ

.DEFAULT_GOAL := build

.PHONY: test

VERSION := 0.0.1

ver:
	-plutil -replace CFBundleShortVersionString -string '${VERSION}' BluJ/Resources/Info.plist

open:
	open BluJ.xcodeproj

build:
	@xcodebuild -project BluJ.xcodeproj -scheme BluJ | xcpretty

github:
	open "https://github.com/mlavergn/bluj"

archive: # Archive - dsym
	@xcodebuild -project BluJ.xcodeproj -scheme BluJ clean archive -configuration release -sdk macos -archivePath ${PROJECT}.xcarchive

export: # Product - ipa / app
	@xcodebuild -exportArchive -archivePath  ${PROJECT}.xcarchive -exportOptionsPlist  ${PROJECT}/exportOptions.plist -exportPath ${PROJECT}.ipa

dmg:
	hdiutil create tmp.dmg -ov -volname "${PROJECT}" -fs HFS+ -srcfolder "dist"
	hdiutil convert tmp.dmg -format UDZO -o ${PROJECT}.dmg 

release:
	zip -r bluj.zip README.md Makefile BluJ BluJ.xcodeproj
	hub release create -m "${VERSION} - BluJ Route Helper" -a bluj.zip -t master "v${VERSION}"
	open "https://github.com/mlavergn/bluj/release"

st:
	open -a SourceTree .