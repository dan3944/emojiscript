{-# LANGUAGE LambdaCase #-}

module Main where

import Control.Arrow ((>>>), (&&&))
import Control.Monad (foldM)
import Control.Monad.Trans.Writer.Lazy (tell, runWriter, execWriter)
import Data.Function ((&))
import Data.List (maximumBy, isPrefixOf)
import Data.Maybe (fromJust)
import Data.Ord (comparing)
import System.Directory (doesFileExist)
import System.Environment (getArgs)
import System.Random (newStdGen, randomR, RandomGen)
import qualified Data.Map.Strict as M

type Mappings = M.Map String String

data Atom = CharLit Char
            | Comment String
            | StringLit String
            deriving (Show)

main :: IO ()
main = getArgs >>= \case
            [] -> putStrLn "Please specify the file name"
            (fileName:rest) -> do
                    let subs = if null rest then "substitutions.txt" else head rest
                    mappings <- getMappings <$> readFile subs
                    mappings' <- extendMappings mappings <$> newStdGen
                    source <- readFile fileName
                    source & parse mappings' & writeFile (fileName ++ ".js")

parse :: Mappings -> String -> String
parse mappings = parseFile >>> replace mappings >>> serialize

getMappings :: String -> Mappings
getMappings = lines >>> map words >>> map ((unwords . tail) &&& head) >>> M.fromList

extendMappings :: RandomGen g => Mappings -> g -> Mappings
extendMappings m g = m `M.union` extension
  where
    write g elem = do
      let (suffix, g') = randomN 8 ('a','z') g
      tell [suffix]
      return g'

    elems = M.elems m
    elems' = execWriter $ foldM write g $ elems
    extension = M.fromList $ zip elems elems'

randomN 0 rng g = ([], g)
randomN n rng g = (x:xs, g'')
  where
    (x,  g')  = randomR rng g
    (xs, g'') = randomN (n - 1) rng g'

replace :: Mappings -> [Atom] -> [Atom]
replace mappings [] = []
replace mappings (Comment   x : xs) = Comment   x : replace mappings xs
replace mappings (StringLit x : xs) = StringLit x : replace mappings xs
replace mappings atoms = if null replaceCandidates
                            then head atoms : replace mappings (tail atoms)
                            else replacement ++ replace mappings (drop (length toReplace) atoms)
    where
        isCharLit (CharLit _) = True
        isCharLit _ = False
        chars = atoms & takeWhile isCharLit & map (\(CharLit c) -> c)
        replaceCandidates = mappings & M.keys & filter (`isPrefixOf` chars)
        toReplace = replaceCandidates & maximumBy (comparing length)
        replacement = mappings & M.lookup toReplace & fromJust & map CharLit

serialize :: [Atom] -> String
serialize = concatMap $ \case
                CharLit c -> [c]
                Comment s -> "/*" ++ s ++ "*/"
                StringLit s -> "\"" ++ s ++ "\""

parseFile :: String -> [Atom]
parseFile (q:s) | isQuote q = StringLit l : parseFile rest
  where
    -- javascript has two quote syntaxes
    isQuote '\'' = True
    isQuote '\"' = True
    isQuote _ = False

    -- accumulate the string literal (using Writer)
    -- and get the final portion
    (rest, l) = runWriter (scanString s)

    scanString (q':s) | (q' == q)   = return s
    scanString (q':s) | isQuote q'  = tell ['\\', q'] >> scanString s
    scanString ('\\':x:s)           = tell ['\\', x]  >> scanString s
    scanString (c:s)                = tell [c]        >> scanString s

parseFile ('/':'/':s) = Comment com : parseFile rest
  where
    (com, rest) = span (/= '\n') s

parseFile ('/':'*':s) = Comment com : parseFile rest
  where
    (rest, com) = runWriter (scanMLC s)
    scanMLC ('*':'/':s) = return s
    scanMLC (c:s) = tell [c] >> scanMLC s

parseFile (c:s) = CharLit c : parseFile s
parseFile "" = []
