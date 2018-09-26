#!/bin/bash
#
# Build two versions of the benchmark suite, and symlink the builds to
# newBuild and baselineBuild.
#

set -e

# Location of this script
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Import functions from common benchmarking scripts
ln -sfn $dir/../Bench-Swift $dir/bench
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

# Build 'new' and "nio" version
# If $REPO and $NEW_COMMIT are set, edit package $REPO to $NEW_COMMIT before building

function cloneProject {
  local projectPath=$1
  local newPath=$2
  pushd $projectPath
  swift package reset
  popd
  if [ -d $newPath ]; then
    preserveDir $newPath
  fi
  cp -R -p $projectPath $newPath
}

cloneProject $dir/latest $dir/latest-nio

pushd $dir/latest/
build "$dir/newBuild" "$REPO" "$NEW_COMMIT"
popd

pushd $dir/latest-nio/
export KITURA_NIO=1
build "$dir/nioBuild" "$REPO" "$NEW_COMMIT"
unset KITURA_NIO
popd

# Build 'baseline' version
pushd $dir/${BASE_VERSION}/
build "$dir/baselineBuild"
popd
