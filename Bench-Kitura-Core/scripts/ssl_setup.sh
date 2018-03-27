#!/bin/bash
#
# Script to perform setup steps prior to executing Kitura benchmarks that use SSL
#

case `uname` in
Darwin)
  # Delete existing keychain
  security delete-keychain swiftperf.keychain || echo "Keychain swiftperf does not exist"
  # Create the keychain with a password
  security create-keychain -p password swiftperf.keychain && echo "New swiftperf keychain created" || echo "ERROR - could not create swiftperf keychain"
  # Make the custom keychain default, which Kitura will use to store the certificate
  security default-keychain -s swiftperf.keychain || echo "ERROR - could not set default keychain"
  # Unlock the keychain
  security unlock-keychain -p password swiftperf.keychain && echo "Keychain unlocked, ready to test" || echo "ERROR - keychain could not be unlocked"
  ;;
*)
  # No actions required on Linux
  echo "SSL setup - nothing to do"
  ;;
esac

