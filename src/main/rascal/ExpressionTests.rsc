
module ExpressionTests

import ExpressionConverter;
import ObjectlangAST;
import ParseTree;
import Node;
import Exception;

// Elimina metadatos antes de comparar AST
Expression cleanAST(Expression expression) {
    return unsetRec(expression);
}

// Literales e identificadores
test bool testNumber() =
    number(5) == cleanAST(convertExpression("5"));

test bool testIdentifier() =
    identifier("persona") == cleanAST(convertExpression("persona"));

test bool testBoolean() =
    booleanLiteral(true) == cleanAST(convertExpression("true"));

test bool testCharLiteral() = 
    cleanAST(convertExpression("\'a\'")) == charLiteral("a");

// Prueba negativa: Objectilang no soporta caracteres de escape
test bool testCharLiteralEscaped() = 
    rejectsExpression("\'\\n\'");

// Cadenas combinadas de accesos y llamadas: a.b(c).d
test bool testChainedMemberAndCall() =
    memberAccess(
        call(
            memberAccess(identifier("a"), "b"),
            [identifier("c")]
        ),
        "d"
    ) == cleanAST(convertExpression("a.b(c).d"));

// Llamadas encadenadas: f(1, 2)(3)
test bool testChainedCalls() =
    call(
        call(identifier("f"), [number(1), number(2)]),
        [number(3)]
    ) == cleanAST(convertExpression("f(1, 2)(3)"));


test bool testTypeIdentifier() =
    typeIdentifier("Persona") == cleanAST(convertExpression("Persona"));

// Operaciones y precedencia
test bool testAddition() =
    addition(number(2), number(3)) == cleanAST(convertExpression("2+3"));

test bool testPrecedence() =
    addition(number(2), multiplication(number(3), number(4)))
        == cleanAST(convertExpression("2+3*4"));

// Expresiones condicionales
test bool testConditional() =
    conditional(
        booleanLiteral(true),
        number(1),
        number(0)
    ) == cleanAST(convertExpression("if true then 1 else 0"));

// Llamadas y accesos
test bool testMemberAccess() =
    memberAccess(identifier("persona"), "edad")
        == cleanAST(convertExpression("persona.edad"));

test bool testCall() =
    call(identifier("calcular"), [number(5)])
        == cleanAST(convertExpression("calcular(5)"));

// Strings
test bool testEmptyString() =
    stringLiteral([]) == cleanAST(convertExpression("\"\""));

test bool testSimpleString() =
    stringLiteral([textPart("Hola mundo")])
        == cleanAST(convertExpression("\"Hola mundo\""));

test bool testInterpolatedString() =
    stringLiteral([
        textPart("Hola "),
        identifierInterpolation("nombre")
    ]) == cleanAST(convertExpression("\"Hola $nombre\""));

// Comentarios entre operaciones
test bool testComment() =
    addition(number(2), number(3))
        == cleanAST(convertExpression("2 + // comentario\n3"));

// Interpolación de expresiones
test bool testExpressionInterpolation() =
    stringLiteral([
        textPart("Resultado: "),
        expressionInterpolation(
            addition(number(2), number(3))
        )
    ]) == cleanAST(convertExpression("\"Resultado: ${2+3}\""));

// Conservación de espacios dentro de strings
test bool testStringSpaces() =
    stringLiteral([
        expressionInterpolation(
            addition(number(2), number(3))
        ),
        textPart(" mensajes")
    ]) == cleanAST(convertExpression("\"${2+3} mensajes\""));

// Condicionales anidados
test bool testNestedConditional() =
    conditional(
        identifier("a"),
        conditional(identifier("b"), number(1), number(2)),
        number(3)
    ) == cleanAST(
        convertExpression("if a then if b then 1 else 2 else 3")
    );

// Escape dentro de strings
test bool testStringEscape() =
    stringLiteral([
        textPart("Hola"),
        escapePart("\\n"),
        textPart("Mundo")
    ]) == cleanAST(convertExpression("\"Hola\\nMundo\""));


// Comprueba que una expresión inválida sea rechazada
bool rejectsExpression(str input) {
    try {
        convertExpression(input);
        return false;
    }
    catch ParseError(_): {
        return true;
    }
}

// Un identificador de variable no puede empezar por mayúscula
// cuando se utiliza en un contexto que exige Identifier.
test bool testInvalidIdentifier() =
    rejectsExpression("2persona");

// No se permiten strings sin cerrar
test bool testUnclosedString() =
    rejectsExpression("\"Hola");

// No se permiten saltos de línea literales dentro de strings
test bool testStringWithNewline() =
    rejectsExpression("\"Hola\nMundo\"");

// No se permiten caracteres fuera del alfabeto definido
test bool testInvalidStringCharacter() =
    rejectsExpression("\"Hola ñandú\"");

// No se permite una suma sin operando derecho
test bool testIncompleteAddition() =
    rejectsExpression("2+");

// ==========================================
// REGRESIÓN: PALABRAS RESERVADAS
// ==========================================

// "negate" debe ser un identificador completo,
// no el operador "neg" aplicado a "ate".
test bool testNegateAsIdentifier() =
    identifier("negate")
        == cleanAST(convertExpression("negate"));

// Las palabras reservadas pueden aparecer dentro
// de identificadores más largos.
test bool testKeywordPrefixesAsIdentifiers() =
    addition(identifier("negate"), identifier("android"))
        == cleanAST(convertExpression("negate + android"));
        