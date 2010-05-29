#!/bin/sh

rm -rf ../Build
rm -rf Frameworks
mkdir Frameworks
ln -s $CAPP_BUILD/Release/AppKit Frameworks/AppKit
ln -s $CAPP_BUILD/Release/Foundation Frameworks/Foundation
ln -s $CAPP_BUILD/Release/Objective-J Frameworks/Objective-J
rm -rf Build
jake
mv Build/Release/SCAuth ../Build
cp -R Test ../Build/Test
cd ../Build
ojtest Test/*.j