module ObjectlangAST

// Declaraciones anticipadas de tipos estructurales
data BlockNode;
data TypeNode;
data OverrideDefinition;

data Expression
    = number(int literal)
    | addition(Expression left, Expression right)
    | subtraction(Expression left, Expression right)
    | multiplication(Expression left, Expression right)
    | division(Expression left, Expression right)
    | modulo(Expression left, Expression right)
    | stringLiteral(list[StringPart] parts)
    | power(Expression left, Expression right)
    | charLiteral(str character)
    | unaryMinus(Expression operand)
    | unaryNeg(Expression operand)
    | identifier(str name)
    | grouped(Expression inner)
    | memberAccess(Expression target, str name)
    | call(Expression target, list[Expression] arguments)
    | lessThan(Expression left, Expression right)
    | greaterThan(Expression left, Expression right)
    | lessOrEqual(Expression left, Expression right)
    | greaterOrEqual(Expression left, Expression right)
    | notEqual(Expression left, Expression right)
    | equal(Expression left, Expression right)
    | inExpression(Expression element, Expression collection)
    | logicalAnd(Expression left, Expression right)
    | logicalOr(Expression left, Expression right)
    | range(Expression from, Expression to)
    | conditional(Expression condition, Expression thenBranch, Expression elseBranch)
    | typeIdentifier(str name)
    | booleanLiteral(bool booleanValue)
    | blockExpression(BlockNode block)
    | newObject(TypeNode objectType,
            list[Expression] arguments,
            list[OverrideDefinition] overrides)
    ;

data StringPart
    = textPart(str content)
    | escapePart(str sequence)
    | identifierInterpolation(str name)
    | expressionInterpolation(Expression expression)
    ;


// ==========================================
// AST DE ESTRUCTURAS
// ==========================================

// Programa completo
data Program
    = moduleProgram(
        list[Declaration] declarations,
        Statement main
    );

// Declaraciones del módulo
data Declaration
    = objectDeclaration(
        str name,
        list[GenericParameter] generics,
        list[TypeNode] superTypes,
        list[ConstructorParameter] constructorArgs
    )
    | methodAssignment(
        str targetType,
        str name,
        Declaration methodDef
    )
    | methodDefinition(
        list[MethodParameter] parameters,
        list[TypeNode] returnTypes,
        list[BlockNode] bodies
    );

// Tipos simples y genéricos
data TypeNode
    = simpleType(str name)
    | genericType(str name, list[TypeNode] typeArgs)
    | tInt()
    | tBool()
    | tChar()
    | tString()
    ; 

// Parámetros
data GenericParameter
    = genericParameter(str variance, str name);

data ConstructorParameter
    = constructorParameter(
        str mutability,
        str name,
        TypeNode parameterType
    );

data MethodParameter
    = methodParameter(str name, TypeNode parameterType);

// Bloques y sentencias
data BlockNode
    = blockNode(list[Statement] statements);

data Statement
    = exprStmt(Expression expression)
    | valDecl(
        str name,
        list[TypeNode] typeAnnotation,
        Expression expression
    )
    | varDecl(
        str name,
        list[TypeNode] typeAnnotation,
        Expression expression
    )
    | assignmentStmt(
        Expression target,
        Expression expression
    )
    | forStmt(
        ForBindingNode binding,
        Statement body
    );

// Patrones y ciclos
data PatternNode
    = idPattern(str name)
    | tuplePattern(str head, list[str] tail);

data ForBindingNode
    = forBinding(
        PatternNode pattern,
        str operator,
        Expression expression
    );

// Métodos sobrescritos dentro de un objeto
data OverrideDefinition
    = overrideDefinition(
        str name,
        list[MethodParameter] parameters,
        TypeNode returnType,
        BlockNode body
    );
