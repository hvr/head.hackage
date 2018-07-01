#!/usr/bin/env bash

set -e

latest_version() {
    #cabal_index=$HOME/.cabal/packages/hackage.haskell.org/01-index.tar
    #tar -tf $cabal_index $pkg | grep '.cabal$' | sort -r | head -n1 | cut -d '/' -f2
    pkg=$1
    curl -s -H "Accept: application/json" -L -X GET http://hackage.haskell.org/package/$pkg/preferred | jq '.["normal-version"] | .[0]' -r
}

split_pkg_version() {
    package=$(echo $1 | sed 's/\(.\+\)-\([0-9]\+\(\.[0-9]\+\)*\)/\1/')
    version=$(echo $1 | sed 's/\(.\+\)-\([0-9]\+\(\.[0-9]\+\)*\)/\2/')
}

for patch in patches/*.patch; do
    split_pkg_version $(basename $patch .patch)
    latest=$(latest_version $package)
    #echo "$patch $package $version $latest "
    if [ "$latest" != "$version" ]; then
        echo "$patch is obsolete (latest version of $package is $latest), removed"
        git rm -q $patch
    fi
done
