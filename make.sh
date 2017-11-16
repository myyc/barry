#!/bin/sh
rm -rf *.love
rm -rf bundle/barry.app
zip -9 -x '*.piko' *.sh *.DS_Store *.git/* bundle/* .gitignore -r barry.love .
if [ `uname` == 'Darwin' ]; then
  cp -r /Applications/love.app bundle/
  mv bundle/love.app bundle/barry.app
  cp barry.love bundle/barry.app/Contents/Resources/
  cp bundle/Info.plist bundle/barry.app/Contents/
  cp bundle/barry.icns bundle/barry.app/Contents/Resources/"OS X AppIcon.icns"
fi
