#!/bin/bash

function installSwift {
  # Make sure correct Swift version is installed
  # -s flag (skip-existing) prevents failure when build already installed
  local version=`cat .swift-version`
  local swiftMajor=`echo $version | cut -d'.' -f1`
  local swiftMinor=`echo $version | cut -d'.' -f2`
  case `uname` in
  Linux)
    swiftenv install $version -s
    ;;
  Darwin)
    # Must be run with sudo on Mac, as builds are installed globally
    sudo swiftenv install $version -s

    # Ensure we select the correct XCode version for this version of swift:
    #   Swift 3.x = XCode 8.3
    #   Swift 4.0.x = XCode 9.2
    #   Swift 4.1.x = XCode 9.4
    #   Swift 4.2.x = XCode 10
    #
    # Note that this relies on having previous versions of XCode installed in a
    # prescribed location (example: /Applications/Xcode8.3.3).

    case "$swiftMajor" in
    3)
      echo "Switching to Xcode 8.3.3 for Swift 3.x"
      sudo xcode-select -s /Applications/Xcode8.3.3.app
      xcode-select -p
      ;;
    4)
      case "$swiftMinor" in
      0)
        echo "Switching to Xcode 9.2 for Swift 4.0.x"
        sudo xcode-select -s /Applications/Xcode9.2.app
        ;;
      1)
        echo "Switching to Xcode 9.4 for Swift 4.1.x"
        sudo xcode-select -s /Applications/Xcode9.4.app
        ;;
      2)
        echo "Switching to Xcode 10.0 for Swift 4.2.x"
        sudo xcode-select -s /Applications/Xcode10.0.app
        ;;
      *)
        echo "Unknown Swift 4 minor version: ${swiftMinor}"
      esac
      xcode-select -p
      ;;
    *)
      echo "Unknown Swift major version: $swiftMajor"
    esac
    ;;
  esac
}
