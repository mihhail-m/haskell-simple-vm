module VM
  ( VM' (..),
    runVM
  ) where

import Instruction

import System.Exit
import Control.Monad.State
import Control.Monad.IO.Class (liftIO)

type FP = Int
type PC = Int
type Stack = [Int]

initStack :: Stack
initStack = []

-- increment counter
incC :: Int -> Int
incC = (+1)

data VM' = VM' {stack :: Stack
               ,fp    :: FP
               ,pc    :: PC
               ,instr :: Instruction
               } deriving (Read)

instance Show VM' where
  show = showVm

showVm :: VM' -> String
showVm (VM' s fp pc instr) =
    "stack: " ++ show s  ++ "\n" ++
    "fp: "    ++ show fp ++ "\n" ++
    "pc: "    ++ show pc ++ "\n" ++
    "instr: " ++ show instr ++ "\n"

initVM :: VM'
initVM = VM' {stack=initStack, fp=0, pc=0, instr=None}

type VM a = StateT VM' IO a

runVM :: [Instruction] -> IO VM'
runVM is = execStateT (mapM_ runInstr is) initVM

runInstr ::Instruction -> VM ()
runInstr i = case i of
  (Loadc val) -> f (loadc val)
  Dup         -> f dup
  Pop         -> f pop
  Add         -> f (appBinOp i (+))
  Sub         -> f (appBinOp i (-))
  Div         -> f (appBinOp i div)
  Mul         -> f (appBinOp i (*))
  Eq          -> f (appLogOp i (==))
  Leq         -> f (appLogOp i (<=))
  Not         -> f notOp
  Printint    -> printint
  Jump        -> undefined
  Jumpz       -> undefined
  (Load val)  -> f (load val)
  Store       -> undefined
  (Slide n)   -> f (slide n)
  Loadsp      -> f loadsp
  Loadfp      -> f loadfp
  Storefp     -> f storefp
  Loadr       -> undefined
  Storer      -> undefined
  Halt        -> liftIO exitSuccess
  where f i = do            -- modifying intermediate state
          vm <- get         -- and printing it
          modify i
          liftIO $ print vm
        printint = do       -- special case
          (VM' xs _ _ _) <- get
          liftIO $ print (xs!!(length xs -1))

-- VM instructions
loadc :: Int -> VM' -> VM'
loadc x (VM' s fp pc i) = VM' {stack   = x:s
                               , fp    = fp
                               , pc    = incC pc
                               , instr = Loadc x
                              }

load :: Int -> VM' -> VM'
load n (VM' (x:xs) fp pc i) = VM' {stack = xs!!n : xs
                                  ,fp    = fp
                                  ,pc    = incC pc
                                  ,instr = Load n
                                  }

slide :: Int -> VM' -> VM'
slide n (VM' (x:xs) fp pc i) = VM' {stack = x : drop n xs
                                   ,fp    = fp
                                   ,pc    = incC pc
                                   ,instr = Slide n
                                   }

dup :: VM' -> VM'
dup (VM' (x:xs) fp pc i) = VM' {stack = x:x:xs
                               ,fp    = fp
                               ,pc    = incC pc
                               ,instr = Dup
                               }

pop :: VM' -> VM'
pop (VM' (x:xs) fp pc i) = VM' {stack = xs
                               ,fp    = fp
                               ,pc    = incC pc
                               ,instr = Pop
                               }

loadsp :: VM' -> VM'
loadsp (VM' xs fp pc i) = VM' {stack = length xs - 1 : xs
                              ,fp    = fp
                              ,pc    = incC pc
                              ,instr = Loadsp
                              }

loadfp :: VM' -> VM'
loadfp (VM' xs fp pc i) = VM' {stack = fp : xs
                              ,fp    = fp
                              ,pc    = incC pc
                              ,instr = Loadfp
                              }

storefp :: VM' -> VM'
storefp (VM' (x:xs) fp pc i) = VM' {stack = xs
                                   ,fp    = x
                                   ,pc    = incC pc
                                   ,instr = Storefp
                                   }

-- Arithmetics
type BinOp = (Int -> Int -> Int)

appBinOp :: Instruction -> BinOp -> VM' -> VM'
appBinOp instr op (VM' (x:y:xs) fp pc i) = VM' {stack  = op y x:xs
                                                ,fp    = fp
                                                ,pc    = incC pc
                                                ,instr = instr
                                                }

-- Logical operations
type LogicalOp = (Int -> Int -> Bool)

appLogOp :: Instruction -> LogicalOp -> VM' -> VM'
appLogOp instr op (VM' (x:y:xs) fp pc i) = VM' {stack = g (op y x):xs
                                               ,fp    = fp
                                               ,pc    = incC pc
                                               ,instr = instr
                                               }
  where g c = fromEnum c -- convert from Bool to Int(ie True -> 1, False -> 0)

notOp :: VM' -> VM'
notOp (VM' (x:xs) fp pc i) = VM' {stack = g x:xs
                                 ,fp    = fp
                                 ,pc    = incC pc
                                 ,instr = Not
                                 }
  where g x = if x == 0 then 1 else 0
