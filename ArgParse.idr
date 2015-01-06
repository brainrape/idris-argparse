-- ------------------------------------------------------------ [ ArgParse.idr ]
-- Description :
-- Copyright   : (c) Jan de Muijnck-Hughes
-- License     : see LICENSE
-- --------------------------------------------------------------------- [ EOH ]
module ArgParse

import Control.Monad.Identity

import public Effects
import public Effect.Exception
import public Effect.State

import public Lightyear.Core
import public Lightyear.Combinators
import public Lightyear.Strings

import public ArgParse.Model

import ArgParse.Parser

%access public

-- -------------------------------------------------------------------- [ Body ]

private
getOpts : (Arg -> Maybe a) -> List Arg -> {[EXCEPTION String]} Eff $ List a
getOpts _    Nil       = pure $ Nil
getOpts conv (x :: xs) = case conv x of
    Nothing => raise "Invalid Option"
    Just o  => do
      os <- getOpts conv xs
      pure (o :: os)

||| Parse arguments and produce a list of options.
|||
||| @conv A user supplied conversion function used to convert..
||| @args The *unmodified* result of calling `System.getArgs` or `Effects.System.geArgs`.
parseArgs : (conv : Arg -> Maybe a)
          -> (args : List String)
          -> {[EXCEPTION String]} Eff $ List a
parseArgs func (a::as) = do
    case parse args (unwords as) of
      Left err  => raise $ err
      Right res => do
        r <- getOpts func res
        pure r
-- ----------------------------------------------------------------- [ Records ]

private
convOpts : a -> (a -> Arg -> a) -> List Arg -> {[EXCEPTION String]} Eff a
convOpts f   _    Nil       = pure f
convOpts ini conv (x :: xs) = do
    os <- convOpts (conv ini x) conv xs
    pure os

||| Parse arguments using a record.
|||
||| @orig The starting value of the record representing the options.
||| @conv A user supplied conversion function used to update the record.
||| @args The *unmodified* result of calling `System.getArgs` or `Effects.System.geArgs`.
parseArgsRec : (orig : a)
             -> (conv : a -> Arg -> a)
             -> (args : List String)
             -> {[EXCEPTION String]} Eff $ a
parseArgsRec ini func (a::as) = do
    case parse args (unwords as) of
      Left err  => raise err
      Right res => do
        r <- convOpts ini func res
        pure r

-- --------------------------------------------------------------------- [ EOF ]
