module Structures

extend Expressions;
  
syntax NewExpr
    = newWithArgs: "new" Type "(" {Expr ","}* ")" ClassBody?
    | newWithBody: "new" Type ClassBody
    | newWithoutArgs: "new" Type !>> "("
    ;

// Integra la creación de objetos como expresión primaria
syntax Primary = NewExpr;

syntax OverrideDef 
  = overrideDef: "override" Identifier name "(" {MethodParam ","}* params ")" ":" Type returnType "=" Block body;

syntax ClassBody 
  = classBody: "{" OverrideDef+ overrides "}";

// Se agregan explicitamente los tipos que se pueden tener para ser definidos
syntax Type 
  = tInt: "Int" !>> [a-zA-Z0-9_]
  | tBool: "Bool" !>> [a-zA-Z0-9_]
  | tChar: "Char" !>> [a-zA-Z0-9_]
  | tString: "String" !>> [a-zA-Z0-9_]
  | simpleType: TypeIdentifier name
  | genericType: TypeIdentifier name "[" {Type ","}+ "]" typeArgs;


syntax TypeAnnotation 
  = typeAnnDef: ":" Type type;

syntax ValDecl =
    valDecl: ValKeyword Identifier name TypeAnnotation? typeAnn "=" Expr expr;

syntax VarDecl 
  = varDecl: "var" Identifier name TypeAnnotation? typeAnn "=" Expr expr;

syntax Assignment 
  = assignStmt: Postfix target "=" Expr expr;

syntax Stmt 
  = valStmt: ValDecl valDecl
  | varStmt: VarDecl varDecl
  | assignmentStmt: Assignment assignment
  | forStmt: ForStmt forStmt
  | exprStmt: Expr expr ;

syntax ModuleItem 
  = objectItem: ObjectDef objectDef
  | methodItem: MethodAssign methodAssign ;

start syntax Module 
  = moduleDef: ModuleItem* items MainMethod main;

syntax MethodAssign 
  = methodAssign: TypeIdentifier targetType "." Identifier name "=" MethodDef methodDef;

syntax MainMethod 
  = mainMethod: "method" [a-zA-Z0-9_] !<< "main" Block block;

syntax ForOp 
  = arrowOp: "\<-" 
  | inOp: "in" ;

syntax Pattern 
  = idPattern: Identifier id
  | tuplePattern: "(" Identifier head "," {Identifier ","}+ tail ")" ;

syntax ForBinding 
  = forBinding: Pattern pattern ForOp op Expr expr ;

syntax ForStmt 
  = forStmt: "for" "(" ForBinding binding ")" Stmt body ;

syntax MethodParam 
  = methodParam: Identifier name ":" Type paramType;

syntax MethodDef 
  = methodDef: "method" "(" {MethodParam ","}* params ")" ReturnType? returnType Block? body;

syntax ObjectDef
    = objectDef: "object" !>> [a-zA-Z0-9_] TypeIdentifier name
               GenericParams? generics 
               Extends? superType 
               ConstructorArgs? constructorArgs;

syntax ConstructorArgs 
  = constructorArgsDef: "(" {ConstructorParam ","}* params ")";

syntax Extends 
  = extendsDef: "extends" Type type;

syntax GenericParams 
  = genericParams: "[" {GenericParam ","}+ params "]";

syntax Variance 
  = covariant: "+"
  | contravariant: "-" ;

syntax Mutability 
  = valMut: "val"
  | varMut: "var" ;


syntax GenericParam 
  = genericParam: Variance? variance TypeIdentifier typeId;

syntax ConstructorParam 
  = constructorParam: Mutability mutability Identifier name ":" Type paramType;


syntax Block
    = block: "{" {Stmt StatementSeparator}+ statements "}"
    | emptyBlock: "{" "}"
    ;

syntax ReturnType 
  = returnTypeDef: ":" Type type;


keyword PalabrasReservadas 
  = "object" | "extends" | "val" | "var" | "method" | "main" | "override" | "new" | "for" | "in";

// Puntos de entrada para diagnosticar ambigüedades
start syntax ValDeclTest = ValDecl;
start syntax StmtTest = Stmt;
start syntax BlockTest = Block;

lexical StatementSeparator = [\n\r] !<< [\n\r];
