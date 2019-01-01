# GHC/head.hackage CI support
#
# See .gitlab-ci.yml in the root of this repository.

# Expects to be run on x86_64.
# bindistTarball should be a fedora27 tarball.
{ bindistTarball }:

let
  # GHC from the given bindist.
  ghc =
    let
      commit = "633c6d7553d0f2c91245bcf47ae539cfdb7aaa13";
      src = fetchTarball {
        url = "https://github.com/bgamari/ghc-artefact-nix/archive/${commit}.tar.gz";
        sha256 = "0yl7dk8drb92ipgph1mxx8my4gy9py27m749zw6ah6np4gvdp9sx";
      };
    in nixpkgs.callPackage "${src}/artifact.nix" {} {
      ncursesVersion = "6";
      bindistTarball =
        if builtins.typeOf bindistTarball == "path"
        then bindistTarball
        else builtins.fetchurl bindistTarball;
    };

  # Build configuration.
  nixpkgs = import ../. {
    ghc = self: ghc;
    haskellOverrides = self: super: rec {
      mkDerivation = drv: super.mkDerivation (drv // {
        doHaddock = false;
        enableLibraryProfiling = false;
        enableExecutableProfiling = false;
        hyperlinkSource = false;
        configureFlags = (drv.configureFlags or []) ++ [
          "--ghc-options=-ddump-timings"
        ];
      });
    };
  };

  # Build dependencies worth caching.
  buildDepends = with nixpkgs; [
    buildPackages.haskellPackages.jailbreak-cabal
    buildPackages.haskellPackages.cabal2nix

    # Ideally the above would be sufficient but these are somehow the wrong
    # derivations. Instead, it's much easier to just cache a simple
    # test package (tagged in this case.
    nixpkgs.haskellPackages.tagged
  ];

  # Get build-time dependencies of a derivation.
  # See https://github.com/NixOS/nix/issues/1245#issuecomment-401642781
  getDepends = pkg: let
    drv = builtins.readFile pkg.drvPath;
    storeDirRe = lib.replaceStrings [ "." ] [ "\\." ] builtins.storeDir;
    storeBaseRe = "[0-9a-df-np-sv-z]{32}-[+_?=a-zA-Z0-9-][+_?=.a-zA-Z0-9-]*";
    re = "(${storeDirRe}/${storeBaseRe}\\.drv)";
    inputs = lib.concatLists (lib.filter lib.isList (builtins.split re drv));
  in map import inputs;

  # The packages which we are here to test
  testedPackages = with nixpkgs.haskell.lib; with nixpkgs.haskellPackages; {
    inherit lens aeson criterion scotty;
    # servant: Don't distribute Sphinx documentation
    servant = overrideCabal servant { postInstall = ""; };
    # singletons: Disable testsuite since it often breaks due to spurious
    # TH-pretty-printing changes
    singletons = dontCheck singletons;
  };

  inherit (nixpkgs) lib;

  transHaskellDeps = drv:
    let
      haskellDeps = drv.passthru.getBuildInputs.haskellBuildInputs or [];
    in [{
      haskellDeps = map (dep: dep.name) haskellDeps;
      drvName = drv.name;
      drvPath = drv.drvPath;
      out = drv.outPath;
      name = drv.passthru.pname;
      version = drv.passthru.version;
    }] ++ lib.concatMap transHaskellDeps haskellDeps;

  summary = {
    pkgs = lib.concatMap transHaskellDeps (lib.attrValues testedPackages);
    roots = map (drv: drv.name) (lib.attrValues testedPackages);
  };

  # Find Job ID of the given job name in the given pipeline
  find-job = nixpkgs.writeScriptBin "find-job.sh" ''
    set -e

    project_id=$1
    pipeline_id=$2
    job_name=$3

    # Access token is a protected environment variable in the head.hackage project and
    # is necessary for this query to succeed. Sadly job tokens only seem to
    # give us access to the project being built.
    ${nixpkgs.curl}/bin/curl \
      --silent --show-error \
      -H "Private-Token: $ACCESS_TOKEN" \
      "https://gitlab.haskell.org/api/v4/projects/$project_id/pipelines/$pipeline_id/jobs?scope[]=success" \
      > resp.json

    job_id=$(${nixpkgs.jq}/bin/jq ". | map(select(.name == \"$job_name\")) | .[0].id" < resp.json)
    if [ "$job_id" = "null" ]; then
      echo "Error finding job $job_name for $pipeline_id in project $project_id:" >&2
      cat resp.json >&2
      rm resp.json
      exit 1
    else
      rm resp.json
      echo -n "$job_id"
    fi
  '';

in {
  inherit nixpkgs ghc testedPackages buildDepends;
  inherit (nixpkgs) haskellPackages lib;
  testedPackageNames = nixpkgs.lib.attrNames testedPackages;
  inherit summary find-job;
}
