#!/bin/bash -e

patches_dir=$(realpath head.hackage/patches)

add_pkg_dirs() {
    local dirs=$@
    echo "packages: $dirs" >> cabal.project.local
    echo "Added $dirs to cabal.project.local"
}

patch_pkg() {
    local patch=$(basename $1)
    local pkg=$(basename $patch .patch)
    local pkg_dir=packages/$pkg
    git -C $pkg_dir apply $patches_dir/$patch.patch
    git -C $pkg_dir commit -a -m "head.hackage.org patch"
}

unpack_patch_pkg() {
    local patch=$(basename $1)
    local pkg=$(basename $patch .patch)
    unpack_pkg $pkg
    patch_pkg $patch
}

unpack_patch_all() {
    for p in $patches_dir/*; do
        patch_pkg $p
    done
}

# Unpack the given package
unpack_pkg() {
    local pkg=$1
    pushd packages
    cabal unpack $pkg
    local pkg_dir="$(ls -d $pkg* | head)"
    if [ -z "$pkg_dir" ]; then
        echo "failed to unpack $pkg"
        exit 1
    fi
    cd $pkg_dir
    git init
    git add .
    git commit -m "Initial commit"
    git tag upstream
    popd
    add_pkg_dirs packages/$pkg_dir
}

update_patches() {
    for p in packages/*; do
        local patch_path=$patches_dir/$(basename $p).patch
        git -C $p diff upstream..HEAD > $patch_path
        git -C $patches_dir add $patch_path
    done
    git -C $patches_dir status .
}

mkdir -p packages

usage() {
    cat <<EOF
usage: $0 MODE ...

Modes:
  unpack \$pkg        hi
EOF
}

case "X$1" in
    Xunpack)
        unpack_pkg $2
        ;;

    Xunpack-all)
        unpack_patch_all
        ;;

    Xunpack-patch)
        patch=$1
        unpack_pkg $(basename $patch .patch)
        patch_pkg $patch
        ;;

    Xupdate-patches)
        update_patches
        ;;

    *)
        echo "unknown mode $1"
        usage
esac
