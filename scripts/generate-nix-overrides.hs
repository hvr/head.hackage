#! /usr/bin/env nix-shell
#! nix-shell -i runghc -p "haskellPackages.ghcWithPackages (ps: [])"
{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TupleSections #-}

import Data.List
import Distribution.Package
import Distribution.Text
import Distribution.Version
import System.Directory
import System.Environment
import System.FilePath
import qualified Data.Map as Map
import Data.Ord

groupPatches :: Ord a => [(a, k)] -> [(a, [k])]
groupPatches assocs = Map.toAscList $ Map.fromListWith (++) [(k, [v]) | (k, v) <- assocs]

generateOverrides :: FilePath -> FilePath -> IO String
generateOverrides prefix patchDir = do
  patches <- listDirectory patchDir
  override_groups <- groupPatches <$> mapM (generateOverride prefix patchDir)
                                           (groupPatches [ (dropExtension pf, decidePatchType pf) | pf <- patches ])
  let overrides = map mkOverride override_groups
  return $ intercalate "\n" overrides

mkOverride :: (PackageName, [([Int], String)]) -> String
mkOverride (display -> pName, patches) =
  unlines $
    [unwords [pName, "= if", superPname, "== null then", superPname]]
     ++ packages ++
    [ "else", superPname, ";"]
  where
    superPname = "super." ++ pName
    quotes s = "\"" ++ s ++ "\""
    packages :: [String]
    packages = map mkPackages (sortBy (comparing fst) patches)
    mkPackages (version, patch) =
      unwords ["else if", superPname ++ ".version == "
                        ,  quotes (intercalate "." (map show version))
                        ," then (", patch, ")"]

override :: FilePath -> FilePath -> FilePath -> String -> PatchType -> String
override prefix patchDir extlessPath nixexpr ptype =
  unwords ["(", patchFunction ptype, nixexpr, prefix </> patchDir </> addExtension extlessPath (patchTypeExt ptype), ")"]

generateOverride :: FilePath -> FilePath -> (FilePath, [PatchType]) -> IO (PackageName, ([Int], String))
generateOverride prefix patchDir (patchExtless, patchTypes) = do
  let pid' :: Maybe PackageId  = simpleParse (takeFileName patchExtless)
  pid <- maybe (fail ("invalid patch file name: " ++ show patchExtless)) return pid'
  let pname = display (packageName pid)
      version = versionNumbers (packageVersion pid)
  return . (packageName pid,) . (version,) $ 
    "dontRevise "
    ++ foldl' (override prefix patchDir patchExtless) ("super."++pname) patchTypes

patchFunction :: PatchType -> String
patchFunction = \case
  CabalPatch  -> "setCabalFile"
  NormalPatch -> "setPatch"

patchTypeExt :: PatchType -> String
patchTypeExt = \case
  CabalPatch  -> ".cabal"
  NormalPatch -> ".patch"

decidePatchType :: FilePath -> PatchType
decidePatchType patch =
  case takeExtension patch of
    ".cabal" -> CabalPatch
    ".patch" -> NormalPatch
    _ -> error $ "Unexpected patch extension: " ++ patch

data PatchType = CabalPatch | NormalPatch deriving Eq

main :: IO ()
main = do
  args <- getArgs
  (prefix, patchDir) <- case args of
                []    -> return ("", "patches")
                [dir] -> return ("", dir)
                [prefix, dir] -> return (prefix, dir)
                _     -> fail "Usage: generate-nix-overrides [<prefix>, patchdir]"
  overrides <- generateOverrides prefix patchDir
  putStrLn "{haskell, suppressedPatches ? {}, suppressedCabals ? {}}:"
  putStrLn "let dontRevise   = pkg: haskell.lib.overrideCabal pkg (old: { editedCabalFile = null; }); in"
  putStrLn "let setCabalFile = pkg: file: if builtins.hasAttr ''${pkg.pname}'' suppressedCabals  then pkg else haskell.lib.overrideCabal pkg (old: { postPatch = ''cp ${file} ${old.pname}.cabal''; }); in"
  putStrLn "let setPatch     = pkg: file: if builtins.hasAttr ''${pkg.pname}'' suppressedPatches then pkg else haskell.lib.appendPatch pkg file; in"

  putStrLn "self: super: {\n"
  putStrLn overrides
  putStrLn "}"
