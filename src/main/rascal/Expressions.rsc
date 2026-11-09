module Expressions

import ParseTree;
extend Lexical;

// Espacios, tabulaciones y saltos de línea
layout Whitespace =
    ([\ \t\n\r] | LayoutComment)*
    !>> [\ \t]
    !>> "//";

// Interpolaciones dentro de strings
syntax StringInterpolation =
    identifierInterpolation: "$" Identifier
  | expressionInterpolation: "${" Expr "}"
  ;

// Fragmentos de texto dentro de strings
lexical StringText =
    ([\ -}] - [\"\\$])+
    !>> ([\ -}] - [\"\\$]);

// Componentes de un string
syntax StringContent =
    textPart: StringText
  | escapePart: EscapeChar
  | StringInterpolation
  ;

// Repetición léxica para conservar los espacios del string
lexical StringItems = StringContent*;

// String completo
lexical StringLiteral =
    @category="string" stringLiteral: "\"" StringItems "\"";

// CharLiteral agregado para soportar literales de un solo caracter
syntax Primary =
    number: IntLiteral
  | identifier: Identifier
  | typeIdentifier: TypeIdentifier
  | charLiteral: CharLiteral
  | booleanLiteral: BoolLiteral
  | StringLiteral
  | grouped: "(" Expr ")"
  ;

syntax Postfix
  = Primary
  | memberAccess: Postfix "." Identifier
  | call: Postfix "(" {Expr ","}* ")"
  ;


syntax UnaryExpr =
    Postfix
  | unaryMinus: "-" UnaryExpr
  | unaryNeg: "neg" !>> [a-zA-Z0-9_] UnaryExpr
  ;

syntax PowExpr =
    UnaryExpr
  | power: UnaryExpr "**" PowExpr
  ;

// Multiplicación, división y módulo
syntax MulExpr =
    PowExpr
  | left (
        multiplication: MulExpr "*" MulExpr
      | division: MulExpr "/" MulExpr
      | modulo: MulExpr "%" MulExpr
    )
  ;

// Suma y resta
syntax AddExpr =
    MulExpr
  | addition: AddExpr "+" MulExpr
  | subtraction: AddExpr "-" MulExpr
  ;

// Comparaciones
syntax CompExpr =
    AddExpr
  | lessThan: AddExpr "\<" AddExpr
  | greaterThan: AddExpr "\>" AddExpr
  | lessOrEqual: AddExpr "\<=" AddExpr
  | greaterOrEqual: AddExpr "\>=" AddExpr
  | notEqual: AddExpr "\<\>" AddExpr
  | equal: AddExpr "==" AddExpr
  ;

// Pertenencia
syntax InExpr =
    CompExpr
  | inExpression: CompExpr "in" CompExpr
  ;

// Operador lógico AND
syntax AndExpr =
    InExpr
  | logicalAnd: AndExpr "and" InExpr
  ;

// Operador lógico OR
syntax OrExpr =
    AndExpr
  | logicalOr: OrExpr "or" AndExpr
  ;

// Rangos
syntax RangeExpr =
    OrExpr
  | range: OrExpr "-\>" OrExpr
  ;

// Expresiones condicionales
syntax IfExpr =
    conditional: "if" Expr "then" Expr "else" Expr
  ;

// Punto de entrada de la gramática
start syntax Expr =
    IfExpr
  | RangeExpr
  ;

// Interpolación de expresiones
syntax ExprInterpolation =
    "${" Expr "}";

// Punto de entrada temporal para pruebas
start syntax ExprInterpolationTest =
    ExprInterpolation;

