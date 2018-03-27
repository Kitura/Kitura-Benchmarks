#!/bin/bash

function installSwift {
  # Make sure correct Swift version is installed
  # -s flag (skip-existing) prevents failure when build already installed
  local version=`cat .swift-version`
  local swiftMajor=`echo $version | cut -d'.' -f1`
  case `uname` in
  Linux)
    swiftenv install $version -s
    ;;
  Darwin)
    # Must be run with sudo on Mac, as builds are installed globally
    sudo swiftenv install $version -s

    # Ensure we select the correct XCode version for this version of swift:
    #   Swift 3.x = XCode 8.3
    #   Swift 4.x = XCode 9
    #
    # Note that this relies on having previous versions of XCode installed in a
    # prescribed location (example: /Applications/Xcode8.3.3).

    case "$swiftMajor" in
    3)
      echo "Switching to Xcode 8.3.3 for Swift 3.x"
      sudo xcode-select -s /Applications/Xcode8.3.3.app/Contents/Developer
      xcode-select -p
      ;;
    4)
      echo "Switching to Xcode 9 for Swift 4.x"
      sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
      xcode-select -p
      ;;
    *)
      echo "Unknown Swift major version: $swiftMajor"
    esac
    ;;
  esac
}
