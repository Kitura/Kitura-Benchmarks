#!/bin/sh

# Determine location of this script
BUILD_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# import install Swift function
. $BUILD_SCRIPT_DIR/install-swift.sh

#
# Builds a Swift project.
#
# First param is the name of the build. If specified, the build will be symlinked to this location.
#
# Second and third parameters are a repository and commit hash, and are optional. If specified,
# this package will be edited to point to that commit before building.
#
# If additional swift build flags are required, these can be specified via the SWIFT_BUILD_FLAGS
# environment variable.
#
function build {
  local pathname=$1	# The build name (build directory)
  local repo=$2		# The repository under evaluation
  local commit=$3 	# The commit that we want to evaluate

  # Make sure correct Swift version is installed
  installSwift

  # Configure packages
  swift package fetch
  if [ ! -z "$repo" ] && [ ! -z "$commit" ]; then
    echo "Configuring Packages"
    # Only works on Swift 3.1+
    swift package edit $repo --revision $commit && echo "Package '$repo' edited, commit '$commit'"
  fi

  # Build the project, exiting early if the build fails
  swift build -c release ${SWIFT_BUILD_FLAGS} || exit $?

  if [ ! -z "$pathname" ]; then
    # Symlink to requested build directory
    ln -sfn $PWD/.build $pathname
  fi
}

#
# Print Swift package versions to a JSON file. json_output.sh must already have been imported.
# The JSON file should already have been created with json_set_file and json_start.
#
# First param is the pathname of the build, and is required.
#
# Second and third params are the repository and commit hash that were specified when build
# was invoked, and are optional. If specified, the fourth param should specify the corresponding
# name of the branch.
# 
# If a repository is specified, then NEW_COMMIT will be set to the short commit hash.
#
function describeBuild {
  local name=$1		# The build name (for display purposes only)
  local path=$2		# The build directory (containing .build)
  local repo=$3		# The repository under evaluation
  local commit=$4 	# The commit that we want to evaluate
  local branchname=$5	# The branch name for the commit (for display purposes only)

  pushd $path > /dev/null
  local swiftVersion=`cat .swift-version`

  json_object_start "$name"
  json_string "Swift" "$swiftVersion"

  case "$swiftVersion" in
  3.0|3.0.1|3.0.2)
    for package in Packages/*
    do
      cd $package
      package=`basename $package`
      branch=`git symbolic-ref --short HEAD`

      json_object_start "${package%-*}"
      json_string "branch" "${branch##*heads/}"
      json_string "commit" "`git rev-parse HEAD | xargs git rev-parse --short`"
      json_string "message" "`git show -s --format=%B $commit`"
      json_object_end
      cd -
    done
    ;;
  *)
    # Note: this relies on Swift 3.1 build layout (SPM implementation detail)
    for package in .build/checkouts/*
    do
      cd $package
      package=`basename $package`
      package="${package%.git*}"

      json_object_start "$package"

      if [ "$package" = "$repo" ]; then
        local hash=`git rev-parse --short $commit`
        # We should be able to get the branch name here. Tail because the first
        # item listed will be our detached HEAD state.
        local branch=`git branch --contains $commit | tail -n 1`
        if [ ! "$branchname" = "$branch" ]; then
            echo "Warning, provided branch name $branchname does not match inferred branch name $branch, using $branchname anyway"
            branch=$branchname
        fi
        # Overwrite NEW_COMMIT with short hash for later
        NEW_COMMIT=$hash
      else
        local hash=`git rev-parse HEAD | xargs git rev-parse --short`
        local branch=`git describe --all`
        branch="${branch##*tags/}"
      fi

      json_string "branch" "$branch"
      json_string "commit" "$hash"
      json_string "message" "`git show -s --format=%B $hash`"
      json_object_end
      cd - >/dev/null
    done
    ;;
  esac
  json_object_end
  popd > /dev/null
}

#
# Creates a new, empty directory of the specified name.
# An existing directory of the same name will be preserved, by renaming to
# originalName_<last-modified-date>
#
function preserveDir {
  local dirName="$1"
  if [ -d "$dirName" ]; then
    local resName="${dirName}_`perl -e 'use File::stat; use Date::Format; print time2str(\"%Y%m%d-%H%M%S\", stat($ARGV[0])->mtime);' \"$dirName\"`"
    echo "Preserving existing directory $dirName as $resName"
    mv $dirName $resName
  fi
  mkdir $dirName
}

