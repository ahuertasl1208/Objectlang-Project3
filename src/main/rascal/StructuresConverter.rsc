module StructuresConverter

import ParseTree;
import ObjectlangAST;
import ExpressionConverter;
import String;

extend Structures;

// =======================================================
// PUNTO DE ENTRADA PRINCIPAL
// =======================================================

Program convertProgram(str input) {
    Tree parsed = parse(#start[Module], input);
    return convertModuleTree(parsed.top);
}

// =======================================================
// CONVERSORES DE MÓDULO Y DECLARACIONES
// =======================================================

Program convertModuleTree(Tree current) {
    if (appl(prod(label("moduleDef", _), _, _), _) := current) {
        list[Declaration] items = [convertDeclaration(item) | item <- getListChildren(current.args[0])];
        Statement main = convertMainMethod(current.args[2]);
        return moduleProgram(items, main);
    }
    throw "Nodo no reconocido como Module: <current>";
}

Statement convertMainMethod(Tree current) {
    return exprStmt(blockExpression(convertBlock(current.args[4]))); 
}

Declaration convertDeclaration(Tree current) {
    
    if (appl(prod(label("objectItem", _), _, _), _) := current) return convertDeclaration(current.args[0]);
    if (appl(prod(label("methodItem", _), _, _), _) := current) return convertDeclaration(current.args[0]);

    if (appl(prod(label("objectDef", _), _, _), _) := current) {
        str name = implode(#str, current.args[2]);
        
        list[GenericParameter] generics = [];
        if (appl(regular(opt(_)), [genTree]) := current.args[4]) {
            generics = [convertGenericParam(g) | g <- getListChildren(genTree.args[2])];
        }

        list[TypeNode] superType = [];
        if (appl(regular(opt(_)), [extTree]) := current.args[6]) {
            superType = [convertType(extTree.args[2])];
        }

        list[ConstructorParameter] constructorArgs = [];
        if (appl(regular(opt(_)), [cArgsTree]) := current.args[8]) {
            constructorArgs = [convertConstructorParam(p) | p <- getListChildren(cArgsTree.args[2])];
        }

        return objectDeclaration(name, generics, superType, constructorArgs);
    }

    if (appl(prod(label("methodAssign", _), _, _), _) := current) {
        str targetType = implode(#str, current.args[0]);
        str name = implode(#str, current.args[4]);
        Declaration methodDef = convertDeclaration(current.args[8]);
        return methodAssignment(targetType, name, methodDef);
    }

    if (appl(prod(label("methodDef", _), _, _), _) := current) {
        list[MethodParameter] params = [convertMethodParam(p) | p <- getListChildren(current.args[4])];

        list[TypeNode] returnType = [];
        if (appl(regular(opt(_)), [rtTree]) := current.args[8]) {
            returnType = [convertType(rtTree.args[2])];
        }

        list[BlockNode] body = [];
        if (appl(regular(opt(_)), [bTree]) := current.args[10]) {
            body = [convertBlock(bTree)];
        }

        return methodDefinition(params, returnType, body);
    }

    throw "Declaración no soportada: <current>";
}

// =======================================================
// CONVERSORES DE PARÁMETROS Y TIPOS
// =======================================================

TypeNode convertType(Tree current) {

    // Determinar etiquetas de tipos 
    if (appl(prod(label("tInt", _), _, _), _) := current) return tInt();
    if (appl(prod(label("tBool", _), _, _), _) := current) return tBool();
    if (appl(prod(label("tChar", _), _, _), _) := current) return tChar();
    if (appl(prod(label("tString", _), _, _), _) := current) return tString();


    if (appl(prod(label("simpleType", _), _, _), _) := current) {
        return simpleType(implode(#str, current.args[0]));
    }
    if (appl(prod(label("genericType", _), _, _), _) := current) {
        str name = implode(#str, current.args[0]);
        list[TypeNode] typeArgs = [convertType(t) | t <- getListChildren(current.args[4])];
        return genericType(name, typeArgs);
    }
    throw "Type no soportado";
}

GenericParameter convertGenericParam(Tree current) {
    if (appl(prod(label("genericParam", _), _, _), _) := current) {
        str variance = "";
        if (appl(regular(opt(_)), [varTree]) := current.args[0]) {
            if (appl(prod(label("covariant", _), _, _), _) := varTree) variance = "+";
            if (appl(prod(label("contravariant", _), _, _), _) := varTree) variance = "-";
        }
        return genericParameter(variance, implode(#str, current.args[2]));
    }
    throw "GenericParam no soportado";
}

ConstructorParameter convertConstructorParam(Tree current) {
    if (appl(prod(label("constructorParam", _), _, _), _) := current) {
        str mutability = "";
        if (appl(prod(label("valMut", _), _, _), _) := current.args[0]) mutability = "val";
        if (appl(prod(label("varMut", _), _, _), _) := current.args[0]) mutability = "var";
        return constructorParameter(mutability, implode(#str, current.args[2]), convertType(current.args[6]));
    }
    throw "ConstructorParam no soportado";
}

MethodParameter convertMethodParam(Tree current) {
    if (appl(prod(label("methodParam", _), _, _), _) := current) {
        return methodParameter(implode(#str, current.args[0]), convertType(current.args[4]));
    }
    throw "MethodParam no soportado";
}

// =======================================================
// CONVERSORES DE BLOQUES Y SENTENCIAS
// =======================================================

BlockNode convertBlock(Tree current) {
    list[Statement] stmts = extractStatements(current.args[2]);
    return blockNode(stmts);
}

list[Statement] extractStatements(Tree current) {
    list[Statement] result = [];

    for (Tree child <- getListChildren(current)) {
        if (appl(prod(label(_, sort("Stmt")), _, _), _) := child) {
            result += [convertStatement(child)];
        }
    }

    return result;
}

Statement convertStatement(Tree current) {
    if (appl(prod(label("valStmt", _), _, _), _) := current) return convertStatement(current.args[0]);
    if (appl(prod(label("varStmt", _), _, _), _) := current) return convertStatement(current.args[0]);
    if (appl(prod(label("assignmentStmt", _), _, _), _) := current) return convertStatement(current.args[0]);
    if (appl(prod(label("forStmt", sort("Stmt")), _, _), _) := current) return convertStatement(current.args[0]);
    if (appl(prod(label("exprStmt", _), _, _), _) := current) return convertStatement(current.args[0]);

    if (appl(prod(label("valDecl", _), _, _), _) := current) {
        str name = implode(#str, current.args[2]);
        list[TypeNode] typeAnn = [];
        if (appl(regular(opt(_)), [tTree]) := current.args[4]) typeAnn = [convertType(tTree.args[2])];
        return valDecl(name, typeAnn, convertExprTree(current.args[8], convertStructuralExpr));
    }
    if (appl(prod(label("varDecl", _), _, _), _) := current) {
        str name = implode(#str, current.args[2]);
        list[TypeNode] typeAnn = [];
        if (appl(regular(opt(_)), [tTree]) := current.args[4]) typeAnn = [convertType(tTree.args[2])];
        return varDecl(name, typeAnn, convertExprTree(current.args[8], convertStructuralExpr));
    }

    if (appl(prod(label("assignStmt", _), _, _), _) := current) {
        return assignmentStmt(convertExprTree(current.args[0], convertStructuralExpr), convertExprTree(current.args[4], convertStructuralExpr));
    }

    if (appl(prod(label("forStmt", sort("ForStmt")), _, _), _) := current) {
        return forStmt(
            convertForBinding(current.args[4]), convertStatement(current.args[8])
        );
    }

    if (appl(prod(sort("Expr"), _, _), _) := current) {
        return exprStmt(convertExprTree(current, convertStructuralExpr));
    }
    throw "Statement no soportado: <current>";
}


ForBindingNode convertForBinding(Tree current) {

    if (appl(prod(label("forBinding", sort("ForBinding")), _, _), _) := current) {
        PatternNode pattern = convertPattern(current.args[0]);
        str op = unparse(current.args[2]);

        return forBinding(
            pattern,
            op,
            convertExprTree(current.args[4], convertStructuralExpr)
        );
    }

    throw "ForBinding no soportado";
}


PatternNode convertPattern(Tree current) {
    if (appl(prod(label("idPattern", _), _, _), _) := current) {
        return idPattern(implode(#str, current.args[0]));
    }
    if (appl(prod(label("tuplePattern", _), _, _), _) := current) {
        str head = implode(#str, current.args[2]);

        list[str] tail = [
            implode(#str, t) | t <- getListChildren(current.args[6])
        ];

        return tuplePattern(head, tail);
    }
    throw "Pattern no soportado";
}

// =======================================================
// CONVERSORES DE NEW EXPRESSION Y OVERRIDES
// =======================================================

Expression convertStructuralExpr(Tree current) {

    if (appl(prod(label("newWithArgs", _), _, _), _) := current ||
        appl(prod(label("newWithBody", _), _, _), _) := current ||
        appl(prod(label("newWithoutArgs", _), _, _), _) := current) {
        return convertNew(current);
    }

    throw "Expresión estructural no soportada: <current>";
}

Expression convertNew(Tree current) {

    if (appl(prod(label("newWithArgs", _), _, _), _) := current) {
        TypeNode t = convertType(current.args[2]);

        list[Expression] arguments = convertArgExpressions(current.args[6], convertStructuralExpr);

        list[OverrideDefinition] overrides = [];
        if (appl(regular(opt(_)), [Tree bodyTree]) := current.args[10]) {
            overrides = convertOverridesList(bodyTree.args[2]);
        }

        return newObject(t, arguments, overrides);
    }

    if (appl(prod(label("newWithBody", _), _, _), _) := current) {
        TypeNode t = convertType(current.args[2]);

        list[OverrideDefinition] overrides =
            convertOverridesList(current.args[4].args[2]);

        return newObject(t, [], overrides);
    }

    if (appl(prod(label("newWithoutArgs", _), _, _), _) := current) {
        TypeNode t = convertType(current.args[2]);
        return newObject(t, [], []);
    }

    throw "NewExpr no soportada";
}

OverrideDefinition convertOverride(Tree current) {
    if (appl(prod(label("overrideDef", _), _, _), list[Tree] currentArgs) := current) {
        str name = implode(#str, currentArgs[2]);
        
        list[MethodParameter] params = convertMethodParamsList(currentArgs[6]);
        
        TypeNode returnType = convertType(currentArgs[12]);
        BlockNode body = convertBlock(currentArgs[16]);
        return overrideDefinition(name, params, returnType, body);
    }
    throw "OverrideDef no soportado";
}

// =======================================================
// FUNCIONES AUXILIARES
// =======================================================

list[OverrideDefinition] convertOverridesList(Tree current) {
    list[OverrideDefinition] res = [];
    for (Tree c <- getListChildren(current)) {
        res += convertOverride(c);
    }
    return res;
}

list[MethodParameter] convertMethodParamsList(Tree current) {
    list[MethodParameter] res = [];
    for (Tree c <- getListChildren(current)) {
        res += convertMethodParam(c);
    }
    return res;
}


list[Tree] getListChildren(Tree current) {

    if (appl(regular(_), list[Tree] args) := current) {
        list[Tree] result = [];

        for (Tree child <- args) {
            // Los separadores literales no son elementos de la lista.
            if (appl(prod(lit(_), _, _), _) := child) {
                continue;
            }

            // Ignorar únicamente nodos de layout.
            if (appl(Production p, _) := child) {
                if (p.def == layouts("Whitespace")) {
                    continue;
                }
            }

            result += getListChildren(child);
        }

        return result;
    }

    return [current];
}
