{-# LANGUAGE DeriveDataTypeable #-}
module Instruction where

import Data.Char
import Data.Data
import Data.Typeable


-- done:
-- loadc, dup, pop, add, sub, div, mul, eq, leq, not
data Instruction =
  None
  | Loadc Int
  | Dup
  | Pop
  | Add
  | Sub
  | Div
  | Mul
  | Eq
  | Leq
  | Not
  | Printint
  | Jump
  | Jumpz
  | Load
  | Store
  | Slide
  | Loadsp
  | Loadfp
  | Storefp
  | Loadr
  | Storer
  | Halt
  deriving (Read,
            Eq,
            Typeable,
            Data) -- need that to show instructions in lowercase

instance Show Instruction where
  show  = showInstr

showInstr :: Instruction -> String
showInstr (Loadc v) = "loadc " ++ show v
showInstr i = showInstr' i
  where showInstr' instr = map toLower . showConstr $ toConstr instr
