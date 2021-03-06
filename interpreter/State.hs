-- Program State
-- Version: 14/06/2017
module State where

-- Internal imports
import Lexer
import Types

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

-- - State
-- Int         Controller counter
-- Scope       Current Scope
-- [Var]       Memory    (Variables)
-- [Statement] Statments (Functions, Procedures and UserTypes)
type State = (Scope, [Var], [Statement])

-- - Initializes the program state
-- Return Initial state
initState :: State
initState = ([], [], [])



-- -----------------------------------------------------------------------------
-- Memory
-- -----------------------------------------------------------------------------

-- --------------------------------------------------------
-- Variables
-- --------------------------------------------------------

-- - Variable
-- (Token, Token) Variable and it's value
-- String         Variable scope ID
type Var = ((Token, Token), String)

-- --------------------------------------
-- Variable handler
-- --------------------------------------

-- - Insert variable
-- Var    Variable
-- State  Current state
-- Return Updated state
insertVariable :: Var -> State -> State
insertVariable var (sc, [], st) = (sc, [var], st)
insertVariable var (sc,  m, st) = (sc, m ++ [var], st)

-- - Update variable
-- Var    Variable
-- State  Current state
-- Return Updated state
updateVariable :: Var -> State -> State
updateVariable _ (_, [], _) = error "Error: Variable not found."
updateVariable ((Id id1 p1, v1), s1) (sc1, ((Id id2 p2, v2), s2) : m1, st1) =
    if id1 == id2 then (sc1, ((Id id1 p2, v1), s1) : m1, st1)
    else
        let (sc2, m2, st2) = updateVariable ((Id id1 p1, v1), s1) (sc1, m1, st1)
        in (sc1, ((Id id2 p2, v2), s2) : m2, st2)

-- - Remove variable
-- Var    Variable
-- State  Current state
-- Return Updated state
removeVariable :: Var -> State -> State
removeVariable _ (_, [], _) = error "Error: Variable not found."
removeVariable ((Id id1 p1, v1), s1) (sc1, ((Id id2 p2, v2), s2) : m1, st1) =
    if id1 == id2 then (sc1, m1, st1)
    else
        let (sc2, m2, st2) = removeVariable ((Id id1 p1, v1), s1) (sc1, m1, st1)
        in (sc2, ((Id id2 p2, v2), s2) : m2, st2)

-- - Get true if the variable is in symbol table, false otherwise
-- Token  Variable ID
-- State  State
-- Return True if the variable is in symbol table, false otherwise
variableIsSet :: Token -> State -> Bool
variableIsSet _ (_, [], _) = False
variableIsSet (Id id1 p1) (sc, (((Id id2 p2), value), s2) : m, st) =
    if id1 == id2 then True
    else variableIsSet (Id id1 p1) (sc, m, st)

-- - Get variable
-- Token  Variable ID
-- State  State
-- Return Variable
getVariable :: Token -> State -> Var
getVariable _ (_, [], _) = error "Error: Variable not found."
getVariable (Id id1 p1) (sc, (((Id id2 p2), value), s2) : m, st) =
    if id1 == id2 then (((Id id2 p2), value), s2)
    else getVariable (Id id1 p1) (sc, m, st)

-- - Get type and value
-- Token  Variable ID
-- State  State
-- Return Variable
getVariableType :: Token -> State -> Token
getVariableType _ (_, [], _) = error "Error: Variable not found."
getVariableType (Id id1 p1) (sc, (((Id id2 p2), value), s2) : m, st) =
    if id1 == id2 then value
    else getVariableType (Id id1 p1) (sc, m, st)



-- -----------------------------------------------------------------------------
-- Scope
-- -----------------------------------------------------------------------------

type Scope = [String]

-- --------------------------------------
-- Scope handler
-- --------------------------------------

-- - Insert scope
-- String Current scope
-- State  Current state
-- Return Updated state
insertScope :: String -> State -> State
insertScope s  ([], m, st) = ([s], m, st)
insertScope s (sc, m, st) = (s:sc, m, st)

-- - Remove scope
-- String Current scope
-- State  Current state
-- Return Updated state
removeScope :: String -> State -> State
removeScope _  ([], _, _) = error "Error: The scope doesn't exits."
removeScope s1 (s2 : sc1, m1, st1) =
    if (s1 == s2) then (sc1, m1, st1)
    else let (sc2, m2, st2) = removeScope s1 (sc1, m1, st1)
         in (s2 : sc2, m2, st2)

-- - Get scope length
-- State Current state
-- Int   Scope length
getScopeLength :: State -> Int
getScopeLength (sc, _, _) = length(sc)

-- getScope ::



-- -----------------------------------------------------------------------------
-- Statements
-- -----------------------------------------------------------------------------

-- - Statement
-- Token            Type
-- Token            Name
-- Token            Return type
-- [(Token, Token)] Parameters
-- [Token]          Body
type Statement = (Token, Token, Token, [(Token, Token)], [Token])

-- --------------------------------------
-- User type handler
-- --------------------------------------

-- - Insert statement
-- Statement Statement
-- State     Current state
-- Return    Updated state
insertStatement :: Statement -> State -> State
insertStatement stmt (sc, m, []) = (sc, m, [stmt])
insertStatement stmt (sc, m, st) = (sc, m, st ++ [stmt])

-- - Get statement
-- Token  Token
-- State  Current state
-- Return Statement
getStatement :: Token -> State -> Statement
getStatement _ (_, _, []) = error "Error: Statement not found."
getStatement (Id id1 p1) (sc, m, (t, (Id id2 p2), r, p, b):st) =
    if id1 == id2 then (t, (Id id2 p2), r, p, b)
    else getStatement (Id id1 p1) (sc, m, st)

-- - Get statement body
-- Token  Token
-- State  Current state
-- Return Statement
getStatementBody :: Token -> State -> [Token]
getStatementBody _ (_, _, []) = error "Error: Statement not found."
getStatementBody (Id id1 p1) (sc, m, (t, (Id id2 p2), r, p, b):st) =
    if id1 == id2 then b
    else getStatementBody (Id id1 p1) (sc, m, st)

-- - Get true if the token is a statement
-- Token  Statement
-- State  State
-- Return True if the token is a statement, false otherwise
statementIsSet :: Token -> State -> Bool
statementIsSet _ (_, _, []) = False
statementIsSet (Id id1 p1) (sc, m, (t, (Id id2 p2), r, p, b):st) =
    if id1 == id2 then True
    else statementIsSet (Id id1 p1) (sc, m, st)
