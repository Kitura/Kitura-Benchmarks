#!/bin/bash
#
# Build two versions of the benchmark suite, and symlink the builds to
# newBuild and baselineBuild.
#

set -e

# Location of this script
dir=$($(cd `dirname $0`) && pwd)

# Get dependencies from Swift-Bench project
if [ ! -d "$dir/bench" ]; then
  pushd $dir > /dev/null
  git clone https://github.com/djones6/Swift-Bench.git bench
  popd > /dev/null
fi

# Change to a specific commit / tag, if SCRIPTS_VERSION is set
if [ ! -z "$SCRIPTS_VERSION" ]; then
  pushd $dir/bench > /dev/null
  git fetch
  git checkout $SCRIPTS_VERSION
  popd > /dev/null
fi

# Import functions from submodule
. $dir/bench/lib/build.sh

# Baseline version of project to compare with. This should match a branch
# of name baseline-<version>
DEFAULT_BASE_VERSION="1.7.0"
if [ -z "$BASE_VERSION" ]; then
  echo "Using default baseline version: $DEFAULT_BASE_VERSION"
  BASE_VERSION="$DEFAULT_BASE_VERSION"
fi

# Platform-specific build flags for this project
case `uname` in
Darwin)
  SWIFT_BUILD_FLAGS="-Xlinker -lc++"
  ;;
*)
  SWIFT_BUILD_FLAGS=""
  ;;
esac

# Build 'new' version
# If $REPO and $NEW_COMMIT are set, edit package $REPO to $NEW_COMMIT before building
pushd $dir/latest/
build "$dir/newBuild" "$REPO" "$NEW_COMMIT"
popd

# Build 'baseline' version
pushd $dir/${BASE_VERSION}/
build "$dir/baselineBuild"
popd
