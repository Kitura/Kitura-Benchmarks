#!/bin/bash
#
# Build two versions of the benchmark suite, and symlink the builds to
# newBuild and baselineBuild.
#

set -e

# Location of this script
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Import functions from common benchmarking scripts
ln -sf $dir/../Bench-Swift $dir/bench
. $dir/bench/lib/build.sh

# Baseline version of project to compare with. This should match a branch
# of name baseline-<version>
DEFAULT_BASE_VERSION="2.3.2"
if [ -z "$BASE_VERSION" ]; then
  echo "Using default baseline version: $DEFAULT_BASE_VERSION"
  BASE_VERSION="$DEFAULT_BASE_VERSION"
fi

# Platform-specific build flags for this project
case `uname` in
Darwin)
  SWIFT_BUILD_FLAGS=""
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
