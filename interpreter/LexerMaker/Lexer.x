{
module Lexer where

import System.IO
import System.IO.Unsafe
}

%wrapper "basic"

$digit = 0-9      -- digits
$alpha = [a-zA-Z]   -- alphabetic characters

tokens :-

  $white+                              ;
  "--".*                               ;
  \" [^\" \\]* \"                      { \s -> String s }
  program                              { \s -> Program }
  :                                    { \s -> Colon }
  ";"                                  { \s -> SemiColon }
  ","                                  { \s -> Comma }
  natural                              { \s -> Type s }
  integer                              { \s -> Type s }
  rational                             { \s -> Type s }
  real                                 { \s -> Type s }
  universal                            { \s -> Type s }
  text                                 { \s -> Type s }
  int                                  { \s -> Type s }
  float                                { \s -> Type s }
  string                               { \s -> Type s }
  "set["                               { \s -> Set_of }
  "]"                                  { \s -> End_Set_of }
  if                                   { \s -> If }
  endif                                { \s -> End_If }
  else                                 { \s -> Else }
  elseif                               { \s -> Else_If }
  endelse                              { \s -> End_Els }
  func                                 { \s -> Function }
  endfunc                              { \s -> End_Function}
  while                                { \s -> While }
  endwhile                             { \s -> End_While }
  end                                  { \s -> End }
  typedef                              { \s -> Typedef }
  :=                                   { \s -> Assign }
  "\in"                                { \s -> Belongs }
  "\cap"                               { \s -> Intersection }
  "\cup"                               { \s -> Union }
  "\subset"                            { \s -> Subset }
  "\stcomp"                            { \s -> Complement }
  "\emptyset"                          { \s -> Empty_Set }
  "{"                                  { \s -> Open_Bracket }
  "}"                                  { \s -> Close_Bracket }
  "("                                  { \s -> Open_Parentheses }
  ")"                                  { \s -> Close_Parentheses }
  "*"                                  { \s -> Multiplication }
  "/"                                  { \s -> Division }
  "+"                                  { \s -> Addition }
  "-"                                  { \s -> Subtraction }
  >=                                   { \s -> GreaterOrEqual }
  "<="                                 { \s -> SmallerOrEqual }
  >                                    { \s -> Greater }
  "<"                                  { \s -> Smaller }
  !                                    { \s -> Denial }
  =                                    { \s -> Equality }
  print                                { \s -> Print }
  $digit+                              { \s -> Int (read s) } -- Int or Natural?
  $digit+.$digit+                      { \s -> Float (read s) } -- Float or Real?
  $alpha [$alpha $digit \_ \']*        { \s -> Id s }

{
-- Each action has type :: String -> Token

-- The token type:
data Token =
  Program           |
  End               |
  Colon             |
  SemiColon         |
  Comma             |
  Assign            |
  Function          |
  End_Function      |
  While             |
  End_While         |
  Belongs           |
  Subset            |
  Complement        |
  Set_of            |
  End_Set_of        |
  If                |
  End_If            |
  Else              |
  Else_If           |
  End_Els           |
  Typedef           |
  Greater           |
  GreaterOrEqual    |
  Smaller           |
  SmallerOrEqual    |
  Denial            |
  Equality          |
  Type String       |
  Id String         |
  Int Int           |
  Float Float       |
  Empty_Set         |
  Intersection      |
  Union             |
  Multiplication    |
  Division          |
  Addition          |
  Subtraction       |
  Open_Bracket      |
  Close_Bracket     |
  Open_Parentheses  |
  Close_Parentheses |
  Print             |
  String String
  deriving (Eq,Show)

getTokens fn = unsafePerformIO (getTokensAux fn)

getTokensAux fn = do {fh <- openFile fn ReadMode;
                    s <- hGetContents fh;
                    return (alexScanTokens s)}
}