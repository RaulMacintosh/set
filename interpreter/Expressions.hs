-- Expression evaluator
-- Version: 09/06/2017
module Expressions where

-- External imports
import Control.Monad.IO.Class
import Text.Parsec
-- Internal imports
import Lexer
import Parser
import Types
import State

-- -----------------------------------------------------------------------------
-- Expression evaluator
-- -----------------------------------------------------------------------------

-- - Unary var
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
getVar :: ParsecT [Token] (Scope, [Var], [Statement]) IO(Token)
getVar = do
            a <- idToken
            s <- getState
            return (getVariableType a s)

-- - Boolean Operations
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
booleanOP :: ParsecT [Token] (Scope, [Var], [Statement]) IO(Token)
booleanOP = equalityToken <|> greaterToken <|> greaterOrEqualToken
            <|> smallerToken <|> smallerOrEqualToken


-- - Aritmetic Operations
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
numberOP :: ParsecT [Token] (Scope, [Var], [Statement]) IO(Token)
numberOP = additionToken <|> subtractionToken <|> multiplicationToken
           <|> divisionToken

-- - Expressions
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
expression :: ParsecT [Token] (Scope, [Var], [Statement]) IO(Token)
expression = try  binaryExpression <|> parentExpression <|> unaryExpression

-- - Unary expression
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
unaryExpression :: ParsecT [Token] (Scope, [Var], [Statement]) IO(Token)
unaryExpression = do
                    a <- natToken <|> intToken <|> realToken <|> boolToken
                        <|> textToken <|> getVar
                    return (a)

-- - Binary expression
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
binaryExpression :: ParsecT [Token] (Scope, [Var], [Statement]) IO(Token)
binaryExpression = do
                    a <- natToken <|> intToken <|> realToken <|> parentExpression
                        <|> boolToken <|> textToken <|> getVar
                    b <- numberOP <|> booleanOP
                    c <- expression
                    return (eval a b c)

-- - Expression with parentheses
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
parentExpression :: ParsecT [Token] (Scope, [Var], [Statement]) IO(Token)
parentExpression = do
                    a <- openParenthesesToken
                    b <- expression <|> parentExpression
                    c <- closeParenthesesToken
                    return (b)

-- - Evaluation
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
eval :: Token -> Token -> Token -> Token
-- Addition
eval (Nat x p)  (Addition _)       (Nat y _)  = Nat  (x + y) p
eval (Nat x p)  (Addition _)       (Int y _)  = Int  (x + y) p
eval (Int x p)  (Addition _)       (Nat y _)  = Int  (x + y) p
eval (Int x p)  (Addition _)       (Int y _)  = Int  (x + y) p
eval (Real x p) (Addition _)       (Nat y _)  = Real (x + integerToFloat(y)) p
eval (Real x p) (Addition _)       (Int y _)  = Real (x + integerToFloat(y)) p
eval (Real x p) (Addition _)       (Real y _) = Real (x + y) p
-- Subtraction
eval (Nat x p)  (Subtraction _)    (Nat y _)  = Nat  (x - y) p
eval (Nat x p)  (Subtraction _)    (Int y _)  = Int  (x - y) p
eval (Int x p)  (Subtraction _)    (Nat y _)  = Int  (x - y) p
eval (Int x p)  (Subtraction _)    (Int y _)  = Int  (x - y) p
eval (Real x p) (Subtraction _)    (Nat y _)  = Real (x - integerToFloat(y)) p
eval (Real x p) (Subtraction _)    (Int y _)  = Real (x - integerToFloat(y)) p
eval (Real x p) (Subtraction _)    (Real y _) = Real (x - y) p
-- Multiplication
eval (Nat x p)  (Multiplication _) (Nat y _)  = Nat  (x * y) p
eval (Nat x p)  (Multiplication _) (Int y _)  = Int  (x * y) p
eval (Int x p)  (Multiplication _) (Nat y _)  = Int  (x * y) p
eval (Int x p)  (Multiplication _) (Int y _)  = Int  (x * y) p
eval (Real x p) (Multiplication _) (Nat y _)  = Real (x * integerToFloat(y)) p
eval (Real x p) (Multiplication _) (Int y _)  = Real (x * integerToFloat(y)) p
eval (Real x p) (Multiplication _) (Real y _) = Real (x * y) p
-- Division
eval (Nat x p)  (Division _) (Nat y _)  = let z = truncate(integerToFloat(x) / integerToFloat(y)) in Nat z p
eval (Nat x p)  (Division _) (Int y _)  = let z = truncate(integerToFloat(x) / integerToFloat(y)) in Int z p
eval (Int x p)  (Division _) (Nat y _)  = let z = truncate(integerToFloat(x) / integerToFloat(y)) in Int z p
eval (Int x p)  (Division _) (Int y _)  = let z = truncate(integerToFloat(x) / integerToFloat(y)) in Int z p
eval (Real x p) (Division _) (Nat y _)  = Real (x / integerToFloat(y)) p
eval (Real x p) (Division _) (Int y _)  = Real (x / integerToFloat(y)) p
eval (Real x p) (Division _) (Real y _) = Real (x / y) p
-- Equality
eval (Nat x p)  (Equality _)  (Nat y _) = Bool (x == y) p
eval (Int x p)  (Equality _)  (Int y _) = Bool (x == y) p
eval (Real x p) (Equality _) (Real y _) = Bool (x == y) p
eval (Text x p) (Equality _) (Text y _) = Bool (x == y) p
--
eval (Nat x p)  (Greater _)  (Nat y _) = Bool (x > y) p
eval (Int x p)  (Greater _)  (Int y _) = Bool (x > y) p
eval (Real x p) (Greater _) (Real y _) = Bool (x > y) p
--
eval (Nat x p)  (GreaterOrEqual _)  (Nat y _) = Bool (x >= y) p
eval (Int x p)  (GreaterOrEqual _)  (Int y _) = Bool (x >= y) p
eval (Real x p) (GreaterOrEqual _) (Real y _) = Bool (x >= y) p
--
eval (Nat x p)  (Smaller _)  (Nat y _) = Bool (x < y) p
eval (Int x p)  (Smaller _)  (Int y _) = Bool (x < y) p
eval (Real x p) (Smaller _) (Real y _) = Bool (x < y) p
--
eval (Nat x p)  (SmallerOrEqual _)  (Nat y _) = Bool (x <= y) p
eval (Int x p)  (SmallerOrEqual _)  (Int y _) = Bool (x <= y) p
eval (Real x p) (SmallerOrEqual _) (Real y _) = Bool (x <= y) p
--
eval (Text x p)  (Addition _)       (Text y _)  = Text (x ++ y) p
eval (Text x p)  (Addition _)       (Nat  y _)  = Text (x ++ (show y)) p
eval (Text x p)  (Addition _)       (Int  y _)  = Text (x ++ (show y)) p
eval (Text x p)  (Addition _)       (Real y _)  = Text (x ++ (show y)) p
eval (Text x p)  (Addition _)       (Bool y _)  = Text (x ++ (show y)) p
