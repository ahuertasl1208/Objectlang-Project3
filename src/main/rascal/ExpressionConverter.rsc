
module ExpressionConverter

import ParseTree;
import ObjectlangAST;

extend Expressions;

// Punto de entrada: código Objectlang -> AST
Expression convertExpression(str input) {
    Tree parsed = parse(#start[Expr], input);
    return convertExprTree(parsed.top);
}


// Conversión estructural predeterminada.
// El conversor independiente de expresiones no admite
// nodos que pertenecen exclusivamente a Structures.
Expression unsupportedStructuralExpr(Tree current) {
    throw "Expresión estructural no soportada en el conversor independiente";
}

// Convierte una producción del árbol sintáctico
// Mantiene la interfaz original para las pruebas existentes.
Expression convertExprTree(Tree current) {
    return convertExprTree(current, unsupportedStructuralExpr);
}

// Permite delegar construcciones estructurales.
Expression convertExprTree(
    Tree current,
    Expression (Tree) convertStructural
) {
    // Expresiones entre paréntesis
    if (appl(prod(label("grouped", _), _, _), _) := current) {
        return grouped(convertExprTree(current.args[2], convertStructural));
    }

    // Operadores binarios
    if (appl(prod(label("addition", _), _, _), _) := current) {
        return addition(
            convertExprTree(current.args[0], convertStructural),
            convertExprTree(current.args[4], convertStructural)
        );
    }

    if (appl(prod(label("subtraction", _), _, _), _) := current) {
        return subtraction(
            convertExprTree(current.args[0], convertStructural),
            convertExprTree(current.args[4], convertStructural)
        );
    }

    if (appl(prod(label("multiplication", _), _, _), _) := current) {
        return multiplication(
            convertExprTree(current.args[0], convertStructural),
            convertExprTree(current.args[4], convertStructural)
        );
    }

    if (appl(prod(label("division", _), _, _), _) := current) {
        return division(
            convertExprTree(current.args[0], convertStructural),
            convertExprTree(current.args[4], convertStructural)
        );
    }

    if (appl(prod(label("modulo", _), _, _), _) := current) {
        return modulo(
            convertExprTree(current.args[0], convertStructural),
            convertExprTree(current.args[4], convertStructural)
        );
    }

    if (appl(prod(label("power", _), _, _), _) := current) {
        return power(
            convertExprTree(current.args[0], convertStructural),
            convertExprTree(current.args[4], convertStructural)
        );
    }

    // Operadores unarios
    if (appl(prod(label("unaryMinus", _), _, _), _) := current) {
        return unaryMinus(convertExprTree(current.args[2], convertStructural));
    }

    if (appl(prod(label("unaryNeg", _), _, _), _) := current) {
        return unaryNeg(convertExprTree(current.args[2], convertStructural));
    }

    // Caso base: números enteros
    if (appl(prod(label("number", _), _, _), _) := current) {
        return implode(#Expression, current);
    }

    // Caso base: identificadores
    if (appl(prod(label("identifier", _), _, _), _) := current) {
        return implode(#Expression, current);
    }

    // Identificadores de tipo: Persona, Mi_Objeto2
    if (appl(prod(label("typeIdentifier", _), _, _), _) := current) {
        return implode(#Expression, current);
    }

    // Literales booleanos: true, false
    if (appl(prod(label("booleanLiteral", _), _, _), _) := current) {
        str booleanText = unparse(current);
        bool booleanValue = booleanText == "true";
        return booleanLiteral(booleanValue);
    }

    // Strings simples e interpolados
    if (appl(prod(label("stringLiteral", _), _, _), _) := current) {
        list[StringPart] parts = [];

        Tree stringItems = current.args[2];

        for (item <- stringItems.args[0].args) {
            parts += convertStringPart(item, convertStructural);
        }

        return stringLiteral(parts);
    }

    if (appl(prod(label("charLiteral", _), _, _), _) := current) {
        str rawText = unparse(current); // Da algo como "'a'"
        return charLiteral(rawText[1..-1]); // Se queda con "a"
    
    }


   
    if (appl(prod(sort("Postfix"), _, _), _) := current) {
        if (size(current.args) == 1) {
            return convertExprTree(current.args[0], convertStructural);
        }
        throw "Caso Postfix inesperado"; // El resto ya lo manejan los label abajo
    }

    // Acceso a miembros 
    if (appl(prod(label("memberAccess", _), _, _), _) := current) {
        Expression base = convertExprTree(current.args[0], convertStructural);
        str name = implode(#str, current.args[4]);
        return memberAccess(base, name);
    }

    //  Llamadas a funciones o métodos 
    if (appl(prod(label("call", _), _, _), _) := current) {
        Expression base = convertExprTree(current.args[0], convertStructural);
        list[Expression] arguments = convertArgExpressions(current.args[4], convertStructural);
        return call(base, arguments);
    }


    // Comparaciones
    if (appl(prod(label("lessThan", _), _, _), _) := current) {
        return lessThan(
            convertExprTree(current.args[0], convertStructural),
            convertExprTree(current.args[4], convertStructural)
        );
    }

    if (appl(prod(label("greaterThan", _), _, _), _) := current) {
        return greaterThan(
            convertExprTree(current.args[0], convertStructural),
            convertExprTree(current.args[4], convertStructural)
        );
    }

    if (appl(prod(label("lessOrEqual", _), _, _), _) := current) {
        return lessOrEqual(
            convertExprTree(current.args[0], convertStructural),
            convertExprTree(current.args[4], convertStructural)
        );
    }

    if (appl(prod(label("greaterOrEqual", _), _, _), _) := current) {
        return greaterOrEqual(
            convertExprTree(current.args[0], convertStructural),
            convertExprTree(current.args[4], convertStructural)
        );
    }

    if (appl(prod(label("notEqual", _), _, _), _) := current) {
        return notEqual(
            convertExprTree(current.args[0], convertStructural),
            convertExprTree(current.args[4], convertStructural)
        );
    }

    if (appl(prod(label("equal", _), _, _), _) := current) {
        return equal(
            convertExprTree(current.args[0], convertStructural),
            convertExprTree(current.args[4], convertStructural)
        );
    }

    // Pertenencia
    if (appl(prod(label("inExpression", _), _, _), _) := current) {
        return inExpression(
            convertExprTree(current.args[0], convertStructural),
            convertExprTree(current.args[4], convertStructural)
        );
    }

    // Operadores lógicos
    if (appl(prod(label("logicalAnd", _), _, _), _) := current) {
        return logicalAnd(
            convertExprTree(current.args[0], convertStructural),
            convertExprTree(current.args[4], convertStructural)
        );
    }

    if (appl(prod(label("logicalOr", _), _, _), _) := current) {
        return logicalOr(
            convertExprTree(current.args[0], convertStructural),
            convertExprTree(current.args[4], convertStructural)
        );
    }

    // Rangos
    if (appl(prod(label("range", _), _, _), _) := current) {
        return range(
            convertExprTree(current.args[0], convertStructural),
            convertExprTree(current.args[4], convertStructural)
        );
    }

    // Expresiones condicionales
    if (appl(prod(label("conditional", _), _, _), _) := current) {
        return conditional(
            convertExprTree(current.args[2], convertStructural),
            convertExprTree(current.args[6], convertStructural),
            convertExprTree(current.args[10], convertStructural)
        );
    }

    // Construcciones propias de la gramática integrada.
    if (appl(prod(label("newWithArgs", _), _, _), _) := current ||
        appl(prod(label("newWithBody", _), _, _), _) := current ||
        appl(prod(label("newWithoutArgs", _), _, _), _) := current) {
        return convertStructural(current);
    }

    // Eliminar envolturas con un único hijo
    if (appl(_, [child]) := current) {
        return convertExprTree(child, convertStructural);
    }

    throw "Producción todavía no soportada";
}



list[Expression] convertArgExpressions(Tree current) {
    return convertArgExpressions(current, unsupportedStructuralExpr);
}

list[Expression] convertArgExpressions(
    Tree current,
    Expression (Tree) convertStructural
) {
    if (appl(prod(sort("Expr"), _, _), _) := current) {
        return [convertExprTree(current, convertStructural)];
    }

    list[Expression] arguments = [];

    if (appl(_, children) := current) {
        for (child <- children) {
            arguments += convertArgExpressions(child, convertStructural);
        }
    }

    return arguments;
}



StringPart convertStringPart(Tree current) {
    return convertStringPart(current, unsupportedStructuralExpr);
}

StringPart convertStringPart(
    Tree current,
    Expression (Tree) convertStructural
) {
    if (appl(prod(label("textPart", _), _, _), _) := current ||
        appl(prod(label("escapePart", _), _, _), _) := current ||
        appl(prod(label("identifierInterpolation", _), _, _), _) := current) {
        return implode(#StringPart, current);
    }

    if (appl(prod(label("expressionInterpolation", _), _, _), _) := current) {
        return expressionInterpolation(
            convertExprTree(current.args[2], convertStructural)
        );
    }

    if (appl(_, [child]) := current) {
        return convertStringPart(child, convertStructural);
    }

    throw "Componente de string todavía no soportado";
}
