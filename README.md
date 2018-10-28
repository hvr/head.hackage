# Overlay Hackage Package Index for GHC HEAD

## How to contribute

Submit PRs with patch(es) relative to the source tarball(s) of
existing Hackage package(s).

- The patches MUST apply cleanly by `patch -p1` when inside the
  original unpacked source-tarball. (Travis CI will verify this when
  you submit a PR).

- The patches SHOULD work with at least GHC HEAD and the most recent
  stable released GHC version (currently this means with GHC 8.6.1 and
  GHC 8.7).

- The patches SHOULD ideally result in the same code being compiled,
  as one of the main purposes of these patches is to make regression
  testing possible. I.e. try to avoid conditional compilation.

- If only the `.cabal` file needs to be modified, a `.cabal` file
  SHOULD be used instead of a `.patch` file. If the changes to the
  `.cabal` file are too invasive (e.g. removing modules, changing the
  structure of the package etc), a `.patch` file must be used.

## How this works

This repo contains `<pkg-id>.patch` and `<pkg-id>.cabal` files in the
[`patches/`](./patches/) folder (where `<pkg-id>` refers to a specific
release of a package, e.g. `lens-4.15.3`).

Once merged to `master`, all package releases whose `<pkg-id>` is
mentioned will enter the *HEAD.hackage* package index; if there is a
`.patch` file, the respective releases tarballs are patched
(i.e. mutated!). If there is a `.cabal` file, it is included as a
revision in the package index. Consequently, if there is only a
`.cabal` file and no `.patch` file, the original source `.tar.gz` is
included verbatimely (i.e. *not* mutated).

If this operation succeeds, the `HEAD.hackage` package index at
http://HEAD.hackage.haskell.org/ is updated to contain the new index
state.

`HEAD.hackage` contains only a small subset of package releases,
and needs to be combined with the main Hackage repository.

Cabal's new nix-style local build facility makes sure that the
modified packages don't contaminate your package databases, while
allowing to maximise sharing via the nix-style package-db cache store.

## How to use


### As an add-on remote repository

It is *not* recommended to add the `HEAD.hackage` repository index to
your global cabal configuration.

Instead, you should mix in the `HEAD.hackage` repository on a
per-project level. Then the packages in the `HEAD.hackage` will
overlay those from the main package index, by adding the repository stanza (as shown on http://head.hackage.haskell.org) to the `cabal.project(.local)` file or use `head.hackage.sh init` (see below).

To workaround some current issues in `cabal` and make it more
convenient, the script
[`scripts/head.hackage.sh`](scripts/head.hackage.sh) is provided,
which facilitates common tasks.

It's been tested on Linux so far. Other operating systems may require
tweaks (patches welcome!).

The main operations provided are

- `head.hackage.sh update`: Resets & syncs the local package download cache for the `HEAD.hackage` repo.

- `head.hackage.sh init`: generates a new `cabal.project` file with a `repository` stanza enabling the `HEAD.hackage` repo locally. This command also takes an optional list of arguments which are included as `optional-packages:` declarations in the resulting `cabal.project` file.

- `head.hackage.sh init-local`: generate a `cabal.project.local` file instead.

- `head.hackage.sh dump-repo`: print `repository` stanza to stdout


### As an add-on local repository

The `HEAD.hackage` package repo can also be generated as a file-based
local repository. The handling is similiar to using `HEAD.hackage` via
a remote repo.

TODO: provide scripting

### As locally patched packages

The process of applying patches can be used in a cabal project with
local packages.

You can add something like `optional-packages: */*.cabal` to your
`cabal.project` file, and then for each package-id with a `.patch` or
`.cabal` file you want to provide as a locally patched package do

```
$ cabal unpack --pristine $PKGID
$ cd $PKGID/
$ patch -p1 -i ${WhereThisGitHubRepoIsCloned}/patches/$PKGID.patch
$ cp ${WhereThisGitHubRepoIsCloned}/patches/$PKGID.cabal ./*.cabal
$ cd ..
```

TODO: implement script

### Adding a patch

The `scripts/patch-tool` script is a tool for conveniently authoring and updating
patches. For instance, if you find that the `doctest` package needs to be
patched first run:
```
$ scripts/patch-tool unpack doctest
```
This will extract a `doctest` source tree to `packages/doctest-$version` and
initialize it as a git repository. You can now proceed to edit the tree as
necessary and run
```
$ scripts/patch-tool update-patches
```
This will create an appropriately-named patch in `patches/` from the edits in
the `doctest` tree.

### Usage with `nix`

`default.nix` is a [Nix](https://nixos.org/nix/) expression which can be used to
build `head.hackage` packages using GHC 8.6.1-alpha2:
```
$ nix build -f ./. haskellPackages.servant
```
It can also be used to build a compiler from a local source tree and use this to
build `head.hackage` packages:
```
$ nix build -f ./. --arg ghc "(import ghc-from-source.nix {ghc-path=$GHC_TREE;})"
```

### Travis CI

The [Travis CI script generator](https://github.com/haskell-hvr/multi-ghc-travis) has recently added support for enabling the `HEAD.hackage` repository automatically for jobs using unreleased GHC versions.

### Nix(Os)

The patches maintained for the `head.hackage` project can also be used with [Nix](https://nixos.org/nix/) (not to be confused with [Cabal's Nix-style local builds](http://cabal.readthedocs.io/en/latest/nix-local-build-overview.html)). See the README in the [`script/`](./scripts) folder and/or the
[*Using a development version of GHC with nix* blogpost](http://mpickering.github.io/posts/2018-01-05-ghchead-nix.html) for more information.

## Other Package Index Overlays

- [Experimental mobile haskell hackage overlay](http://hackage.mobilehaskell.org/)
- [GHCJS package overlay for Hackage](http://hackage-ghcjs-overlay.nomeata.de/)
- [Hackage Package Candidate Overlay](http://cand.hackage.haskell.org/)

