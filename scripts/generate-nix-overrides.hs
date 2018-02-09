#! /usr/bin/env nix-shell
#! nix-shell -i runghc -p "haskellPackages.ghcWithPackages (ps: [])"
{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE ScopedTypeVariables #-}

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
  override_groups <- groupPatches <$> mapM (generateOverride prefix patchDir) patches
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


generateOverride :: FilePath -> FilePath -> FilePath -> IO (PackageName, ([Int], String))
generateOverride prefix patchDir patch = do
  let pid' :: Maybe PackageId  = simpleParse (takeBaseName patch)
  pid <- maybe (fail ("invalid patch file name: " ++ show patch)) return pid'
  let pname = display (packageName pid)
      version = versionNumbers (packageVersion pid)
  return $ (packageName pid, (version,
    unwords [ "haskell.lib.appendPatch", "super."++pname, prefix </> patchDir </> patch ]))

main :: IO ()
main = do
  args <- getArgs
  (prefix, patchDir) <- case args of
                []    -> return ("", "patches")
                [dir] -> return ("", dir)
                [prefix, dir] -> return (prefix, dir)
                _     -> fail "Usage: generate-nix-overrides [<prefix>, patchdir]"
  overrides <- generateOverrides prefix patchDir
  putStrLn "{haskell}: self: super: {\n"
  putStrLn overrides
  putStrLn "}"
