# Using the nix overrides

The most convenient way to use the nix script is to make a new top level
attribute for the overriden package set.

I achieve this using an overlay.

`~/.config/nixpkgs/overlays.nix` contains a list of overlays which augment the
main package set. I just have one which I keep in my home directory for convenience.

```
[ (import ~/overlay.nix) ]
```

Then in `~/overlay.nix`, I define a new attribute which contains the patch and
cabal file overrides.

```nix
self: super:
{
  # An attribute which contains the head overrides.
  patches = super.callPackage <local-path-to-overrides.nix>
              { patches = <path-to-patch-folder>; };


  # A modified package set intented to be used with ghcHEAD
  ghcHEAD = super.haskell.packages.ghcHEAD.override
  { overrides = sel: sup:
                  # The patches from the directory
                  ((super.callPackage self.patches {} sel sup)
                  # Any more local overrides you want.
                  // { mkDerivation = drv: sup.mkDerivation
                        ( drv // { jailbreak = true; doHaddock = false; });
                        generic-deriving = super.haskell.lib.dontCheck sup.generic-deriving;
                       });
                   };
}
```

The `patches` attribute is the file which `generate-nix-overrides.hs` creates.
You need to set the correct paths to `overrides.nix` and the patch folder.

For example, if you have cloned `head.hackage` into your home directory, you would
set them to `~/head.hackage/scripts/overrides.nix` and `~/head.hackage/patches`
respectively. Having a local installation is desirable as when using `head.hackage`
you have to commonly add new patches and cabal files to `patches`.

Once you have setup this overlay, you can test your new attribute by trying to build
a package.

```
nix-shell -p "ghcHEAD.ghcWithPackages (ps: [ps.primitive])"
```

and it might work, or it might not :). If it doesn't work, add a patch to your
patches directory and try again.
