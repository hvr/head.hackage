#!/bin/bash

set -e

case "X$TRAVIS_EVENT_TYPE" in
    Xpull_request)
    ;;

    Xpush)
    ;;

    X*)
        echo "INFO: not a PR; ignoring"
        exit 0
        ;;

    X)
        echo "ERROR: TRAVIS_EVENT_TYPE not set"
        exit 1
        ;;
esac

if [ -z "$TRAVIS_COMMIT_RANGE" ]; then
    echo "ERROR: TRAVIS_COMMIT_RANGE not set"
    exit 1
fi

CHANGED_FILES=($(git diff --name-only $TRAVIS_COMMIT_RANGE))


for FN in "${CHANGED_FILES[@]}"; do
    if [ ! -f "$FN" ]; then
        echo "ignoring $FN (not a file (anymore))"
        continue
    fi   
    
    if [[ "$FN" =~ ^patches/(.*)[.]patch$ ]]; then
        echo "--------------------------------------------------------------------------------"
        echo "detected patch file '$FN'"
        if [[ "$FN" =~ ^patches/([A-Za-z0-9-]+)-([0-9.]+)[.]patch$ ]]; then
            PKGN="${BASH_REMATCH[1]}"
            PKGV="${BASH_REMATCH[2]}"

            echo "Patch filename looks valid (name = '$PKGN', version = '$PKGV')"

            rm -rf travis.tmp/
            mkdir -p travis.tmp/
            pushd travis.tmp/
            echo "...downloading original tar-ball (w/o revised .cabal file)..."
            wget --no-verbose "https://hackage.haskell.org/package/$PKGN-$PKGV.tar.gz"
            echo "...unpacking..."
            tar -xf "$PKGN-$PKGV.tar.gz"
            cd "$PKGN-$PKGV/"
            echo "...applying patch..."
            patch -p1 -i "../../$FN"

            echo "Patch could be applied succesfully!"
            
            popd
        else
            echo "invalid package-id"
            exit 1
        fi
        echo "================================================================================"
    else
        echo "ignoring $FN"
        continue
    fi
done


echo DONE
