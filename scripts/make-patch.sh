#!/bin/sh
set -e

die () {
    echo "ERROR: $1" >& 2
    exit 1
}

usage () {
    echo "Usage:
  ${0##*/} <name>-<version>

  Will roughly perform the following operations:
  $ git fetch \$hvr/head.hackage
  $ git checkout -b <name>-<version> \$hvr/head.hackage/master
  $ mv <name>-<version> <name>-<version>-patched
  $ cabal unpack --pristine <name>-<version>
  $ diff -ru <name>-<version> <name>-<version>-patched > \$head.hackage/patches/<name>-<version>.patch
  $ mv -f <name>-<version>-patched <name>-<version>
  $ git add patches/<name>-<version>.patch
  $ git commit -m \"Adds <name>-<version>.patch\"
  $ git push

  All that's left is opening the PR against \$hvr/head.hackage"
    exit 1
}

if [ -z "$1" ]; then
    usage
fi

if [ ! -f "$HOME/.head.hackage" ]; then
    die "$HOME/.head.hackage file not found."
fi
source "$HOME/.head.hackage"

if [ -z "$HEAD_HACKAGE_CLONE_PATH" ]; then
    die "head.hackage local repository ('\$HEAD_HACKAGE_CLONE_PATH') not set; please edit $HOME/.head.hackage."
fi
if [ ! -d "$HEAD_HACKAGE_CLONE_PATH" ]; then
    die "head.hackage local repository ('\$HEAD_HACKAGE_CLONE_PATH') doesn't seem to exist; please edit $HOME/.head.hackage."
fi
if [ ! -d "$HEAD_HACKAGE_CLONE_PATH/.git" ]; then
    die "head.hackage local repository ('\$HEAD_HACKAGE_CLONE_PATH') doesn't seem to be a git repository; please edit $HOME/.head.hackage."
fi

UPSTREAM_FETCH_NAME=$(git -C "$HEAD_HACKAGE_CLONE_PATH" remote -v |grep "hvr/head.hackage.*fetch"|awk -F\  '{ print $1 }')

if [ -z "$UPSTREAM_FETCH_NAME" ] ; then
    echo "no hvr/head.hackage remote found. Adding..."
    git -C "$HEAD_HACKAGE_CLONE_PATH" remote add hvr https://github.com/hvr/head.hackage.git
    UPSTREAM_FETCH_NAME="hvr"
fi

git -C "$HEAD_HACKAGE_CLONE_PATH" fetch "$UPSTREAM_FETCH_NAME"
git -C "$HEAD_HACKAGE_CLONE_PATH" checkout -b "$1" "$UPSTREAM_FETCH_NAME/master"

if [ ! -d "$HEAD_HACKAGE_CLONE_PATH/patches" ]; then
    die "$HEAD_HACKAGE_CLONE_PATH/patches does not exist!"
fi

if [ -f "$HEAD_HACKAGE_CLONE_PATH/patches/$1.patch" ]; then
    die "$HEAD_HACKAGE_CLONE_PATH/patches/$1.patch already exists!"
fi

echo "creating patch..."
mv "$1" "$1-patched"
cabal unpack --pristine "$1"

# diff returns 0 for no changes; 1 for some changes; and 2 for trouble
set +e
diff -ru "$1" "$1-patched" > "$HEAD_HACKAGE_CLONE_PATH/patches/$1.patch"
exit_status=$?
set -e
if [ $exit_status -eq 1 ]; then
    echo "creating commit..."
    git -C "$HEAD_HACKAGE_CLONE_PATH" add "patches/$1.patch"
    git -C "$HEAD_HACKAGE_CLONE_PATH" commit -m "Adds $1.patch"
    git -C "$HEAD_HACKAGE_CLONE_PATH" push origin

    echo "Please go to https://github.com/hvr/head.hackage"
else
    echo "failed to create patch... exit: $?"
    "$HEAD_HACKAGE_CLONE_PATH/patches/$1.patch"
    git -C "$HEAD_HACKAGE_CLONE_PATH" checkout master
    git -C "$HEAD_HACKAGE_CLONE_PATH" branch -d "$1"
fi
echo "moving $1-patched to $1"
rm -fR "$1"
mv "$1-patched" "$1"

