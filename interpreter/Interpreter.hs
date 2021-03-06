-- Interpreter
-- Version: 14/06/2017
module Interpreter where

-- External imports
import Data.List
import Data.List.Split
import Text.Parsec
import Control.Monad
import System.IO.Unsafe
import Control.Monad.IO.Class
-- Internal imports
import Lexer
import Types
import Parser
import State
import Keywords
import Expressions

-- -----------------------------------------------------------------------------
-- Parser to nonterminals
-- -----------------------------------------------------------------------------

-- - Program
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
program :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
program = do
    a <- programToken <?> "program statement."
    b <- idToken <?> "program name."
    -- Update scope
    updateState(insertScope(getIdName b))
    c <- stmts
    d <- endToken <?> "end statement."
    -- Update scope
    updateState(removeScope(getIdName b))
    e <- idToken <?> "program name."
    eof
    return (a:[b] ++ c ++ [e])

-- --------------------------------------------------------
-- Variable declarations
-- --------------------------------------------------------

-- - Variable declarations
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
varDecls :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
varDecls = do
    first <- try varDecl <|> arrayDecl
    next  <- remainingVarDecls
    return (first ++ next)

-- - Variable declaration remaining
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
remainingVarDecls :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
remainingVarDecls = (do a <- varDecls
                        return (a)) <|> (return [])

-- - Variable declaration
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
varDecl :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
varDecl = do
    a <- try varDeclN <|> varDeclA
    return (a)

-- - Variable declaration
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
varDeclN :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
varDeclN = do
    a <- typeToken <?> "variable type."
    b <- colonToken <?> "colon."
    c <- idToken <?> "variable name."
    d <- semiColonToken <?> "semicolon."
    s <- getState
    -- Check if the variable already exists
    if ((variableIsSet c s) == False) then do
        -- Add the declared variable
        updateState(insertVariable((c, getDefaultValue(a)), "main"))
        -- s <- getState
        -- liftIO (print s)
        return (a:b:c:[d])
    else
        error ("The variable " ++ (getTokenName c) ++ " in position "
            ++ (getTokenPosition c) ++ " already exists.")

-- - Variable declaration and assignment
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
varDeclA :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
varDeclA = do
    a <- typeToken <?> "variable type."
    b <- colonToken <?> "colon."
    c <- idToken <?> "variable name."
    d <- assignToken
    e <- expression
    f <- semiColonToken <?> "semicolon."
    s <- getState
    -- Check if the variable already exists
    if ((variableIsSet c s) == False) then do
        -- Add the declared variable
        updateState(insertVariable((c, (cast (getDefaultValue a) e)), "main"))
        -- s <- getState
        -- liftIO (print s)
        return (a:b:c:d:e:[f])
    else
        error ("The variable " ++ (getTokenName c) ++ " in position "
            ++ (getTokenPosition c) ++ " already exists.")

-- - Array declaration
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
arrayDecl :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
arrayDecl = do
    a <- typeToken <?> "variable type."
    b <- openBracketToken
    c <- typeToken <?> "array type."
    d <- commaToken
    e <- expression
    f <- closeBracketToken
    g <- colonToken <?> "colon."
    h <- idToken <?> "variable name."
    i <- semiColonToken <?> "semicolon."
    s <- getState
    -- Check index
    if ((checkNatType e) == True) then do
        -- Check if the variable already exists
        if ((variableIsSet h s) == False) then do
            -- Add the declared variable
            updateState(insertVariable((h, getDefaultArrayValue a c e), "main"))
            return (a:b:c:d:e:f:g:h:[i])
        else
            error ("Error: The variable " ++ (getTokenName h) ++ " in position "
                ++ (getTokenPosition h) ++ " already exists.")
    else
        error "Error: Invalid size value."



-- --------------------------------------------------------
-- Other statements
-- --------------------------------------------------------

-- - Statements
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
stmts :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
stmts = do
    first <- varDecls <|> assign <|> printf <|> inputf <|> ifStmt <|> whileStmt
    next  <- remainingStmts
    return (first ++ next)

-- - Statements remaining
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
remainingStmts :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
remainingStmts = (do a <- stmts
                     return (a)) <|> (return [])

-- - Assign
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
assign :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
assign = do
    a <- try assignVar <|> assignVarArray
    return (a)

-- - Assign var
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
assignVar :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
assignVar = do
    a <- idToken <?> "variable name."
    b <- assignToken <?> "assign."
    -- Calculates the expression
    c <- expression
    d <- semiColonToken <?> "semicolon."
    s <- getState
    -- Check if the types are compatible
    if (not (compatible (getVariableType a s) c)) then fail "Type mismatch."
    else
        do
            -- Update variable value
            updateState(updateVariable(((a, (cast (getVariableType a s) c)),
                        "main")))
            return (a:b:[c])

-- - Assign array
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
assignVarArray :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
assignVarArray = do
    a <- idToken <?> "variable name."
    bf <- getInput
    setInput (a:bf)
    s <- getState
    -- Check if is an array
    if (checkArrayType(getVariableType a s) == True) then do
        a <- idToken <?> "variable name."
        b <- openBracketToken
        c <- expression
        d <- closeBracketToken
        e <- assignToken <?> "assign."
        -- Calculates the expression
        f <- expression
        g <- semiColonToken <?> "semicolon."
        -- Check if the types are compatible
        if (not (compatible (getDefaultValue(getArrayType(getVariableType a s))) c)) then fail "Type mismatch."
        else do
            -- Update variable value
            updateState(updateVariable((a, (setArrayItem (getVariableType a s) c (cast (getDefaultValue(getArrayType (getVariableType a s))) f) )),
                        "main"))
            s <- getState
            -- s <- getState
            -- liftIO (print s)
            return (a:b:c:d:e:[f])
    else
        return ([a])



-- -----------------------------------------------------------------------------
-- IF STATEMENT
-- -----------------------------------------------------------------------------

-- - If
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
ifStmt :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
ifStmt = do
    s <- getState
    a <- ifToken <?> "if."
    b <- openParenthesesToken <?> "parentheses (."
    -- Calculates the expression
    c <- expression
    d <- closeParenthesesToken <?> "parentheses )."
    -- Update scope
    updateState(insertScope(("if" ++ (show (getScopeLength s)))))
    -- Check if the expression is true
    if ((getValue c) == "True") then do
        -- Get the next statement
        e <- ignoreToken
        af <- getInput
        -- Add back the last readed statement
        setInput (e:af)
        -- Check if the token is a END_IF
        if (((checkEndIfStmt e) == True)) then do
            e <- endIfToken
            -- Update scope
            updateState(removeScope(("if" ++ (show (getScopeLength s)))))
            return (a:b:c:d:[e])
        else
            -- Check if the token is a ELSE or ELSE_IF
            if (((checkElseIfStmt e) == True)
                    || ((checkElseStmt e) == True)) then do
                -- Ignore statements
                bf <- getInput
                let loop = do
                    f <- ignoreToken
                    when ((checkEndStmt f) == True) (error "endif statement not found.")
                    when (((columnEndIfStmt f) /= (columnIfStmt a))) loop
                loop
                af <- getInput
                -- Update scope
                updateState(removeScope(("if" ++ (show (getScopeLength s)))))
                return (a:b:c:[d] ++ (bf \\ af))
            else do
                -- Run statements
                e <- stmts
                -- Ignore other statements
                bf <- getInput
                let loop = do
                    f <- ignoreToken
                    when ((checkEndStmt f) == True) (error "endif statement not found.")
                    when (((columnEndIfStmt f) /= (columnIfStmt a))) loop
                loop
                af <- getInput
                -- Update scope
                updateState(removeScope(("if" ++ (show (getScopeLength s)))))
                return (a:b:c:[d] ++ e ++ (bf \\ af))
    else do
        -- Check if the expression is false
        if ((getValue c) == "False") then do
            -- Update scope
            updateState(removeScope(("if" ++ (show (getScopeLength s)))))
            -- Get the next statement
            e <- ignoreToken
            af <- getInput
            -- Add back the last readed statement
            setInput (e:af)
            -- Check if the token is a END_IF
            if (((checkEndIfStmt e) == True)) then do
                e <- endIfToken
                return (a:b:c:d:[e])
            else do
                -- Update scope
                updateState(insertScope(("if" ++ (show (getScopeLength s)))))
                -- Ignore other statements
                bf <- getInput
                let loop = do
                    f <- ignoreToken
                    when ((checkEndStmt f) == True) (error "endif statement not found.")
                    when (((columnElseStmt f) /= (columnIfStmt a))
                        && ((columnElseIfStmt f) /= (columnIfStmt a))
                        && ((columnEndIfStmt f) /= (columnIfStmt a))) loop
                loop
                af <- getInput
                -- Add back the last readed statement
                setInput (let y:x = reverse (bf \\ af) in y:af)
                bf1 <- getInput
                -- Get the next statement
                e <- ignoreToken
                -- Check if the token is a ELSE
                if ((checkElseStmt e) == True) then do
                    -- Get the next statement
                    e <- ignoreToken
                    af1 <- getInput
                    -- Add back the last readed statement
                    setInput (e:af1)
                    -- Check if the token is a END_IF
                    if (((checkEndIfStmt e) == True)) then do
                        e <- endIfToken <?> "endif."
                        return (a:b:c:[d] ++ (bf \\ af) ++ [e])
                    else do
                        e <- stmts
                        f <- endIfToken <?> "endif."
                        -- Update scope
                        updateState(removeScope(("if" ++ (show (getScopeLength s)))))
                        return (a:b:c:[d] ++ e ++ [f])
                else
                    -- Check if the token is a ELSE_IF
                    if ((checkElseIfStmt e) == True) then do
                        af1 <- getInput
                        -- Add back the last readed statement
                        setInput (let y:x = reverse (bf1 \\ af1) in y:af)
                        e <- elseIfStmt
                        -- Update scope
                        updateState(removeScope(("if" ++ (show (getScopeLength s)))))
                        return (a:b:c:[d] ++ (bf \\ af) ++ e)
                    else
                        {-e <- stmts
                        f <- endIfToken
                        -- Update scope
                        updateState(removeScope(("if" ++ (show (getScopeLength s)))))-}
                        return (a:b:c:[d] ++ (bf \\ af))
        else do
            error "Error: it's not a boolean expresion."

-- - Else if
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
elseIfStmt :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
elseIfStmt = do
    s <- getState
    a <- elseIfToken <?> "elseif."
    b <- openParenthesesToken <?> "parentheses (."
    -- Calculates the expression
    c <- expression
    d <- closeParenthesesToken <?> "parentheses )."
    -- Update scope
    updateState(insertScope(("if" ++ (show (getScopeLength s)))))
    -- Check if the expression is true
    if ((getValue c) == "True") then do
        -- Get the next statement
        e <- ignoreToken
        af <- getInput
        -- Add back the last readed statement
        setInput (e:af)
        -- Check if the token is a END_IF
        if (((checkEndIfStmt e) == True)) then do
            e <- endIfToken <?> "endif."
            -- Update scope
            updateState(removeScope(("if" ++ (show (getScopeLength s)))))
            return (a:b:c:d:[e])
        else
            -- Check if the token is a ELSE or ELSE_IF
            if (((checkElseIfStmt e) == True)
                    || ((checkElseStmt e) == True)) then do
                    -- Ignore other statements
                bf <- getInput
                let loop = do
                    f <- ignoreToken
                    when ((checkEndStmt f) == True) (error "endif statement not found.")
                    when (((columnEndIfStmt f) /= (columnElseIfStmt a))) loop
                loop
                af <- getInput
                -- Update scope
                updateState(removeScope(("if" ++ (show (getScopeLength s)))))
                return (a:b:c:[d] ++ (bf \\ af))
            else do
                -- Run statements
                e <- stmts
                -- Ignore other statements
                bf <- getInput
                let loop = do
                    f <- ignoreToken
                    when ((checkEndStmt f) == True) (error "endif statement not found.")
                    when (((columnEndIfStmt f) /= (columnElseIfStmt a))) loop
                loop
                af <- getInput
                -- Update scope
                updateState(removeScope(("if" ++ (show (getScopeLength s)))))
                return (a:b:c:[d] ++ e ++ (bf \\ af))
    else do
        -- Check if the expression is false
        if ((getValue c) == "False") then do
            -- Update scope
            updateState(removeScope(("if" ++ (show (getScopeLength s)))))
            -- Get the next statement
            e <- ignoreToken
            af <- getInput
            -- Add back the last readed statement
            setInput (e:af)
            -- Check if the token is a END_IF
            if (((checkEndIfStmt e) == True)) then do
                e <- endIfToken
                return (a:b:c:d:[e])
            else do
                -- Update scope
                updateState(insertScope(("if" ++ (show (getScopeLength s)))))
                -- Ignore other statements
                bf <- getInput
                let loop = do
                    f <- ignoreToken
                    when ((checkEndStmt f) == True) (error "endif statement not found.")
                    when (((columnElseStmt f) /= (columnElseIfStmt a))
                        && ((columnElseIfStmt f) /= (columnElseIfStmt a))
                        && ((columnEndIfStmt f) /= (columnElseIfStmt a))) loop
                loop
                af <- getInput
                -- Add back the last readed statement
                setInput (let y:x = reverse (bf \\ af) in y:af)
                bf1 <- getInput
                -- Get the next statement
                e <- ignoreToken
                -- Check if the token is a ELSE
                if ((checkElseStmt e) == True) then do
                    -- Get the next statement
                    e <- ignoreToken
                    af1 <- getInput
                    -- Add back the last readed statement
                    setInput (e:af1)
                    -- Check if the token is a END_IF
                    if (((checkEndIfStmt e) == True)) then do
                        e <- endIfToken <?> "endif."
                        return (a:b:c:d:[e])
                    else do
                        e <- stmts
                        f <- endIfToken <?> "endif."
                        -- Update scope
                        updateState(removeScope(("if" ++ (show (getScopeLength s)))))
                        return (a:b:c:[d])
                else
                    -- Check if the token is a ELSE_IF
                    if ((checkElseIfStmt e) == True) then do
                        af1 <- getInput
                        -- Add back the last readed statement
                        setInput (let y:x = reverse (bf1 \\ af1) in y:af)
                        f <- elseIfStmt <?> "elseif."
                        -- Update scope
                        updateState(removeScope(("if" ++ (show (getScopeLength s)))))
                        return (a:b:c:[d])
                    else
                        {-e <- stmts
                        f <- endIfToken
                        -- Update scope
                        updateState(removeScope(("if" ++ (show (getScopeLength s)))))-}
                        return (a:b:c:[d] ++ (bf \\ af))
        else do
            error "Error: it's not a boolean expresion."



-- -----------------------------------------------------------------------------
-- WHILE STATEMENT
-- -----------------------------------------------------------------------------

-- - While statement
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
whileStmt :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
whileStmt = do
    -- Get Input
    wb <- getInput
    a <- whileToken <?> "while."
    -- Check while block
    let loop = do
        f <- ignoreToken
        when ((checkEndStmt f) == True) (error "endwhile statement not found.")
        when (((columnEndWhileStmt f) /= (columnWhileStmt a))) loop
    loop
    we <- getInput
    -- Executes while
    let loopwhile = do
        setInput (wb \\ we)
        f <- ignoreToken
        f <- ignoreToken
        c <- expression
        setInput (wb \\ we)
        w <- runWhile
        when ((getValue c) == "True") loopwhile
    loopwhile
    setInput (we)
    return (we)

-- - While statement
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
runWhile :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
runWhile = do
    s <- getState
    a <- whileToken <?> "while."
    b <- openParenthesesToken <?> "parentheses (."
    -- Calculates the expression
    c <- expression
    d <- closeParenthesesToken <?> "parentheses )."
    -- Update scope
    updateState(insertScope(("while" ++ (show (getScopeLength s)))))
    -- Check if the expression is true
    if ((getValue c) == "True") then do
        -- Get the next statement
        e <- ignoreToken
        af <- getInput
        -- Add back the last readed statement
        setInput (e:af)
        -- Check if the token is a END_WHILE
        if (((checkEndWhileStmt e) == True)) then do
            e <- endWhileToken <?> "endWhile."
            -- Update scope
            updateState(removeScope(("while" ++ (show (getScopeLength s)))))
            return (a:b:c:d:[e])
        else do
            -- Run statements
            e <- stmts
            -- Ignore other statements
            bf <- getInput
            let loop = do
                f <- ignoreToken
                when (((columnEndWhileStmt f) /= (columnWhileStmt a))) loop
            loop
            af <- getInput
            -- Update scope
            updateState(removeScope(("while" ++ (show (getScopeLength s)))))
            return (a:b:c:[d] ++ e ++ (bf \\ af))
    else do
        -- Check if the expression is false
        if ((getValue c) == "False") then do
            return (a:b:c:[d])
        else do
            error "Error: it's not a boolean expresion."



-- -----------------------------------------------------------------------------
-- OTHER STATEMENTS
-- -----------------------------------------------------------------------------

-- - Print
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
printf :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
printf = do
    a <- printToken <?> "print."
    b <- openParenthesesToken <?> "parentheses (."
    -- Calculates the expression
    c <- expression
    d <- closeParenthesesToken
    e <- semiColonToken
    -- Prints in terminal
    liftIO (putStrLn ((getValue c)))
    return (a:b:c:d:[e])

-- - Input
-- ParsecT                     ParsecT
-- [Token]                     Token list
-- (Scope, [Var], [Statement]) State
inputf :: ParsecT [Token] (Scope, [Var], [Statement]) IO([Token])
inputf = do
    a <- inputToken <?> "input."
    b <- openParenthesesToken <?> "parentheses (."
    c <- idToken <?> "Variable name."
    d <- closeParenthesesToken <?> "parentheses )."
    e <- semiColonToken <?> "semicolon ;."
    f <- liftIO $ getLine
    s <- getState
    -- Check if variable exists
    if (variableIsSet c s) then
        -- Check if is an array
        if ((checkArrayType(getVariableType c s)) == True) then do
            -- Check array size
            if (let (Nat y _) = getArraySize(getVariableType c s) in y == length(splitOn "," f)) then do
                -- Update variable value
                updateState(updateVariable((c,
                    let (Array (si, t, _) y) = (getVariableType c s) in (Array (si, t, (getArrayValue(getVariableType c s) ++ (toToken (getVariableType c s) (splitOn "," f)))) y)), "main"))
                return (a:b:[c])
            else
                error "Error: The entry does not match the size of the array."
        else do
            -- Update variable value
            updateState(updateVariable((c,
                (inputCast (getVariableType c s)
                    (Text (show f) (let (Id _ y) = c in y)))), "main"))
            return (a:b:[c])
    else
        error "Error: variable not found."



-- -----------------------------------------------------------------------------
-- Starts parser
-- -----------------------------------------------------------------------------

-- - Parser
-- [Token]          Token list
parser :: [Token] -> IO (Either ParseError [Token])
parser tokens = runParserT program initState "Error message" tokens
