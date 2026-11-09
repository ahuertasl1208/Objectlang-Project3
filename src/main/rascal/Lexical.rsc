module Lexical

// Palabras reservadas de Objectlang
keyword Keywords =
    "val" | "var"
  | "method" | "main"
  | "object" | "extends" | "override"
  | "if" | "then" | "else"
  | "for" | "in"
  | "new"
  | "true" | "false"
  | "and" | "or" | "neg"
  ;

// Agregar palabras reservadas para los tipos de datos requeridos
keyword TypeKeywords = "Int" | "Bool" | "Char" | "String";

// Identificadores
lexical Identifier =
    ([a-z][a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) \ Keywords;

// No dejamos que los identificadores de tipo sean palabras reservadas
lexical TypeIdentifier =
    ([A-Z][a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) \ TypeKeywords;

start syntax TypeIdentifierTest = TypeIdentifier;

// Literales enteros
lexical IntLiteral =
    @category="number" [0-9]+ !>> [0-9];

// Literales booleanos
syntax BoolLiteral = "true" | "false";

// Reglas temporales de prueba
start syntax IntegerTest = IntLiteral;
start syntax BooleanTest = BoolLiteral;

// Literales de un solo caracter
lexical CharLiteral =
    @category="string" [\'] ![\'\n\r] [\'];
    
start syntax CharTest = CharLiteral;

lexical SimpleStringChar = ![\"\\$];

lexical EscapeChar =
    "\\\""
  | "\\$"
  | "\\\\"
  | "\\n"
  | "\\t"
  | "\\r"
  ;

// Caracteres permitidos en comentarios
// Caracteres básicos
lexical Letter = [a-zA-Z];
lexical Digit = [0-9];
lexical Space = " ";
lexical Tab = "\t";
lexical Newline = "\n" | "\r";

// Signos de puntuación permitidos por Objectlang
lexical PunctuationChar =
    "!" | "#" | "%" | "&" | "\'"
  | "(" | ")" | "*" | "+" | ","
  | "-" | "." | "/" | ":" | ";"
  | "\<" | "=" | "\>" | "?" | "@"
  | "[" | "]" | "^" | "_" | "`"
  | "{" | "|" | "}"
  ;

// Caracteres permitidos dentro de comentarios
lexical CommentChar =
    Letter
  | Digit
  | Space
  | Tab
  | PunctuationChar
  | "\\"
  | "\""
  | "$"
  ;

// Comentario de una línea
lexical Comment =
    "//" CommentChar* Newline?
  ;

// Comentario para el layout: no consume el salto de línea
lexical LayoutComment =
    "//" ![\n\r]* $;

// Entrada temporal para probar comentarios
start syntax CommentTest = Comment;

lexical SimpleStringLiteral =
    "\"" (SimpleStringChar | EscapeChar)* "\"";

lexical IdentifierInterpolation =
    "$" Identifier;

lexical InterpolatedStringLiteral =
    "\"" (SimpleStringChar | EscapeChar | IdentifierInterpolation)* "\"";

start syntax InterpolatedStringTest = InterpolatedStringLiteral;

start syntax StringTest = SimpleStringLiteral;

// Regla temporal para pruebas
start syntax IdentifierTest = Identifier;

lexical ValKeyword =
    @category="keyword" "val" !>> [a-zA-Z0-9_];
