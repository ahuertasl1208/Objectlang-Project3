module Checker

import Structures; 
import ObjectlangAST;
import ParseTree;
import String;
import StructuresConverter;

// Extendemos TypePal para poder agregar tipos y funciones collect
extend analysis::typepal::TypePal;

// pt es el arbol de parseo. Funcion para revisar en caso de errores o retorna vacio.
TModel checkObjectlang(start[Module] pt) {
    // Quitar espacios blancos y comentarios para solo quedarnos con la logica. 
    Tree innerModule = pt has top ? pt.top : pt;
    
    // Anotar clases, funciones y variables que existan y determina que tenga sentido.
    return collectAndSolve(innerModule);
}

// ==========================================
// TIPOS INTERNOS DE OBJECTLANG
// ==========================================

// Extendemos AType, definido originalmente por TypePal.
data AType
    = primitiveType(str name)
    | objectType(str name)
    | genericObjectType(str name, list[AType] arguments)
    | typeParameterType(str name)
    | functionType(list[AType] parameters, AType returnType)
    | voidType()
    | anyType()
    ;

// ==========================================
// ROLES DE IDENTIFICADORES
// ==========================================

data IdRole
    = objectId()
    | typeParameterId()
    | variableId()
    | methodId()
    | parameterId()
    ;

// ==========================================
// ROLES DE SCOPES
// ==========================================

data ScopeRole
    = objectScope()
    | methodScope()
    | blockScope()
    ;

// Relacion entre un metodo y su objeto propietario.
data PathRole
    = methodOwnerPath()
    ;

// ==========================================
// REPRESENTACION LEGIBLE DE TIPOS
// ==========================================

str prettyAType(primitiveType(str name)) = name;

str prettyAType(objectType(str name)) = name;

str prettyAType(typeParameterType(str name)) = name;

str prettyAType(genericObjectType(str name, list[AType] arguments)) =
    "<name>[<intercalate(", ", [prettyAType(a) | AType a <- arguments])>]";

str prettyAType(functionType(list[AType] parameters, AType returnType)) =
    "Function";

str prettyAType(voidType()) = "Void";

str prettyAType(anyType()) = "Any";

str prettyAType(AType t) = "<t>";

// ==========================================
// CONVERSION DE TIPOS AL MODELO DE TYPEPAL
// ==========================================

// Tipos primitivos
AType toAType(tInt()) = primitiveType("Int");

AType toAType(tBool()) = primitiveType("Bool");

AType toAType(tChar()) = primitiveType("Char");

AType toAType(tString()) = primitiveType("String");

// Tipos de objetos
AType toAType(simpleType(str name)) =
    objectType(name);

// Tipos genericos
AType toAType(genericType(str name, list[TypeNode] args)) =
    genericObjectType(
        name,
        [toAType(arg) | TypeNode arg <- args]
    );

// ==========================================
// RECOLECCION DE DEFINICIONES
// ==========================================

// Recorre las declaraciones del modulo.
void collect(Module current, Collector c) {

    // Funciones predefinidas de ObjectLang.
    c.predefine(
        "print",
        methodId(),
        current,
        defType(
            functionType([anyType()], voidType())
        )
    );

    c.predefine(
        "println",
        methodId(),
        current,
        defType(
            functionType([anyType()], voidType())
        )
    );

    // Relacionar nombres de objetos con sus definiciones.
    map[str, ObjectDef] objects = ();

    for (ModuleItem item <- current.items) {
        if (item is objectItem) {

            ObjectDef obj = item.objectDef;
            str objectName = "<obj.name>";

            objects[objectName] = obj;

            collect(obj, c);
        }
    }

    // Guardar los scopes reales de los objetos.
    map[str, loc] objectScopes = ();

    for (str objectName <- objects) {

        ObjectDef obj = objects[objectName];

        c.enterScope(obj);

        objectScopes[objectName] = c.getScope();

        c.leaveScope(obj);
    }

    // Segunda pasada: registrar las asignaciones de metodos.
    for (ModuleItem item <- current.items) {
        if (item is methodItem) {

            collect(
                item.methodAssign,
                c,
                objectScopes
            );
        }
    }

    collect(current.main, c);

    // Reglas semanticas sobre el AST, complementarias a la resolucion TypePal.
    checkProgramSemantics(current, c);
}

// Recorre cada elemento del modulo.
void collect(ModuleItem current, Collector c) {

    if (current is objectItem) {
        collect(current.objectDef, c);
    }

    if (current is methodItem) {
        collect(current.methodAssign, c);
    }
}

// Registra los objetos declarados.
void collect(ObjectDef current, Collector c) {
    str name = "<current.name>";

    c.define(
        name,
        objectId(),
        current,
        defType(objectType(name))
    );

    // Verificar el tipo indicado en extends.
    if (appl(regular(opt(_)), [extTree]) := current.args[6]) {

        collect(extTree.args[2], c);
    }

    // Cada objeto tiene su propio scope.
    c.enterScope(current);

    // Registrar los parametros genericos del objeto.
    if (appl(regular(opt(_)), [genTree]) := current.args[4]) {

        for (Tree param <- getListChildren(genTree.args[2])) {

            str paramName = implode(#str, param.args[2]);

            c.define(
                paramName,
                typeParameterId(),
                param.args[2],
                defType(typeParameterType(paramName))
            );
        }
    }

    // ==========================================
    // PARAMETROS DEL CONSTRUCTOR
    // ==========================================

    if (appl(regular(opt(_)), [argsTree]) := current.args[8]) {

        for (Tree param <- getListChildren(argsTree.args[2])) {

            str paramName = implode(#str, param.args[2]);

            AType paramType =
                toAType(convertType(param.args[6]));

            c.define(
                paramName,
                parameterId(),
                param.args[2],
                defType(paramType)
            );

            // Resolver la referencia al tipo declarado.
            collect(param.args[6], c);
        }
    }

    c.leaveScope(current);
}

void collect(MainMethod current, Collector c) {

    c.enterScope(current);

    collect(current.block, c);

    c.leaveScope(current);
}

void collect(Block current, Collector c) {

    if (current is emptyBlock) {
        return;
    }

    c.enterScope(current);

    for (Stmt stmt <- getListChildren(current.args[2])) {
        collect(stmt, c);
    }

    c.leaveScope(current);
}

void collect(Stmt current, Collector c) {

    if (current is valStmt) {
        collect(current.valDecl, c);
    }

    if (current is varStmt) {
        collect(current.varDecl, c);
    }

    // Assignment, ForStmt y Expr se analizaran en los siguientes pasos.
}

void collect(ValDecl current, Collector c) {

    str name = implode(#str, current.name);

    // Tipo provisional cuando no existe anotacion.
    AType declaredType = anyType();

    // Revisar si existe una anotacion de tipo.
    if (appl(regular(opt(_)), [annTree]) := current.typeAnn) {

        Tree typeTree = annTree.args[2];

        declaredType = toAType(convertType(typeTree));

        // Comprobar que el tipo declarado exista.
        collect(typeTree, c);
    }

    // Registrar la variable con su tipo declarado.
    c.define(
        name,
        variableId(),
        current.name,
        defType(declaredType)
    );
}

void collect(VarDecl current, Collector c) {

    str name = implode(#str, current.name);

    AType declaredType = anyType();

    if (appl(regular(opt(_)), [annTree]) := current.typeAnn) {

        Tree typeTree = annTree.args[2];

        declaredType = toAType(convertType(typeTree));

        collect(typeTree, c);
    }

    c.define(
        name,
        variableId(),
        current.name,
        defType(declaredType)
    );
}

// ==========================================
// REFERENCIAS A TIPOS
// ==========================================

void collect(Type current, Collector c) {

    // Referencia a un tipo simple: Animal, Dog, A...
    if (current is simpleType) {
        c.use(
            current.name,
            {objectId(), typeParameterId()}
        );
    }

    // Referencia a un tipo generico: List[Dog]
    if (current is genericType) {

        c.use(
            current.name,
            {objectId()}
        );

        // Verificar recursivamente los tipos internos.
        for (Tree arg <- getListChildren(current.args[4])) {
            collect(arg, c);
        }
    }

}

// ==========================================
// RELACION ENTRE OBJETOS Y METODOS
// ==========================================

void collect(MethodAssign current, Collector c) {

    // Scope de la asignacion del metodo.
    c.enterScope(current);

    // Conectar este scope con el objeto propietario.
    c.addPathToDef(
        current.targetType,
        {objectId()},
        methodOwnerPath()
    );

    // Construir la firma del metodo.
    str methodName = implode(#str, current.name);

    list[AType] parameterTypes = [];

    for (Tree param <- getListChildren(current.methodDef.args[4])) {
        parameterTypes += [
            toAType(convertType(param.args[4]))
        ];
    }

    // Si no declara retorno, consideramos void.
    AType returnType = voidType();

    if (appl(regular(opt(_)), [returnTree]) := current.methodDef.args[8]) {
        returnType = toAType(convertType(returnTree.args[2]));
    }

    // Registrar el metodo con su firma.
    c.define(
        methodName,
        methodId(),
        current.name,
        defType(functionType(parameterTypes, returnType))
    );

    // Analizar la definicion del metodo.
    collect(current.methodDef, c);

    c.leaveScope(current);
}

void collect(
    MethodAssign current,
    Collector c,
    map[str, loc] objectScopes
) {

    // Registrar la asignacion y resolver su objeto.
    collect(current, c);

    str ownerName = implode(#str, current.targetType);
    str methodName = implode(#str, current.name);

    // El objeto inexistente ya se reporta mediante addPathToDef.
    if (ownerName in objectScopes) {

        // Construir la firma del metodo.
        list[AType] parameterTypes = [];

        for (Tree param <- getListChildren(current.methodDef.args[4])) {
            parameterTypes += [
                toAType(convertType(param.args[4]))
            ];
        }

        AType returnType = voidType();

        if (appl(regular(opt(_)), [returnTree]) := current.methodDef.args[8]) {
            returnType = toAType(convertType(returnTree.args[2]));
        }

        // Registrar el metodo en el scope de su objeto.
        c.defineInScope(
            objectScopes[ownerName],
            methodName,
            methodId(),
            current.name,
            defType(functionType(parameterTypes, returnType))
        );
    }
}

// ==========================================
// PARAMETROS Y RETORNO DE METODOS
// ==========================================

void collect(MethodDef current, Collector c) {

    c.enterScope(current);

    // Parametros del metodo.
    for (Tree param <- getListChildren(current.args[4])) {

        str paramName = implode(#str, param.args[0]);

        AType paramType =
            toAType(convertType(param.args[4]));

        c.define(
            paramName,
            parameterId(),
            param.args[0],
            defType(paramType)
        );

        // Comprobar existencia del tipo declarado.
        collect(param.args[4], c);
    }

    // Tipo de retorno, si existe.
    if (appl(regular(opt(_)), [returnTree]) := current.args[8]) {
        collect(returnTree.args[2], c);
    }

    c.leaveScope(current);
}

// ==========================================
// COMPROBACION SEMANTICA DE EXPRESIONES
// ==========================================

// Este analisis utiliza el AST que ya emplea el interprete. Los nombres
// inexistentes en anotaciones siguen siendo responsabilidad de TypePal.

bool isUnknown(AType t) = t == anyType();

str typeName(AType t) = prettyAType(t);

AType declaredTypeOf(list[TypeNode] ts) =
    size(ts) == 0 ? anyType() : toAType(ts[0]);

void validateTypeArity(AType t, map[str, Declaration] objects,
                       Collector c, Tree source) {
    if (t is objectType && t.name in objects) {
        Declaration obj = objects[t.name];
        if (obj is objectDeclaration && size(obj.generics) > 0)
            c.report(error(source,
                "Generic object `<t.name>` requires <size(obj.generics)> type arguments"));
    }
    if (t is genericObjectType) {
        if (t.name in objects) {
            Declaration obj = objects[t.name];
            if (obj is objectDeclaration && size(obj.generics) != size(t.arguments))
                c.report(error(source,
                    "Generic object `<t.name>` expects <size(obj.generics)> type arguments, got <size(t.arguments)>"));
        }
        for (AType arg <- t.arguments) validateTypeArity(arg, objects, c, source);
    }
}

map[str, AType] genericBindings(str name, list[AType] args,
                                 map[str, Declaration] objects) {
    map[str, AType] result = ();
    if (name in objects) {
        Declaration d = objects[name];
        if (d is objectDeclaration) {
            for (int i <- [0 .. size(d.generics)]) {
                if (i < size(args)) result[d.generics[i].name] = args[i];
            }
        }
    }
    return result;
}

AType substituteType(AType t, map[str, AType] bindings) {
    if (t is typeParameterType && t.name in bindings) return bindings[t.name];
    if (t is objectType && t.name in bindings) return bindings[t.name];
    if (t is genericObjectType)
        return genericObjectType(t.name,
            [substituteType(a, bindings) | AType a <- t.arguments]);
    return t;
}

bool subtypeOf(AType actual, AType expected,
               map[str, Declaration] objects) {
    if (actual == expected || isUnknown(actual) || isUnknown(expected)) return true;

    if (actual is genericObjectType && expected is genericObjectType &&
        actual.name == expected.name && size(actual.arguments) == size(expected.arguments)) {
        if (!(actual.name in objects)) return false;
        Declaration obj = objects[actual.name];
        if (!(obj is objectDeclaration) || size(obj.generics) != size(actual.arguments)) return false;
        for (int i <- [0 .. size(actual.arguments)]) {
            str variance = obj.generics[i].variance;
            AType a = actual.arguments[i];
            AType b = expected.arguments[i];
            if (variance == "+" && !subtypeOf(a, b, objects)) return false;
            if (variance == "-" && !subtypeOf(b, a, objects)) return false;
            if (variance == "" && a != b) return false;
        }
        return true;
    }

    str actualName = "";
    if (actual is objectType) actualName = actual.name;
    if (actual is genericObjectType) actualName = actual.name;
    if (actualName == "" || !(actualName in objects)) return false;

    // La herencia simple se recorre con un conjunto de visitados para
    // evitar ciclos infinitos en programas erroneos.
    set[str] visited = {};
    str cursor = actualName;
    while (cursor in objects && !(cursor in visited)) {
        visited += {cursor};
        Declaration obj = objects[cursor];
        if (!(obj is objectDeclaration) || size(obj.superTypes) == 0) break;
        AType parent = toAType(obj.superTypes[0]);
        if (parent == expected) return true;
        if (parent is objectType) cursor = parent.name;
        else break;
    }
    return false;
}

void reportMismatch(Collector c, Tree source, AType actual, AType expected,
                    map[str, Declaration] objects) {
    if (!subtypeOf(actual, expected, objects)) {
        c.report(error(source,
            "Type mismatch: expected <typeName(expected)> but found <typeName(actual)>"));
    }
}

Declaration getMethod(str owner, str methodName,
                      map[str, Declaration] objects,
                      map[str, Declaration] methods) {
    set[str] visited = {};
    str cursor = owner;
    while (!(cursor in visited) && cursor in objects) {
        visited += {cursor};
        str key = "<cursor>.<methodName>";
        if (key in methods) return methods[key];
        Declaration obj = objects[cursor];
        if (!(obj is objectDeclaration) || size(obj.superTypes) == 0) break;
        TypeNode parent = obj.superTypes[0];
        if (parent is simpleType) cursor = parent.name;
        else break;
    }
    return methodDefinition([], [], []);
}

bool hasMethod(str owner, str methodName,
               map[str, Declaration] objects, map[str, Declaration] methods) {
    set[str] visited = {};
    str cursor = owner;
    while (cursor in objects && !(cursor in visited)) {
        visited += {cursor};
        if ("<cursor>.<methodName>" in methods) return true;
        Declaration obj = objects[cursor];
        if (!(obj is objectDeclaration) || size(obj.superTypes) == 0) break;
        TypeNode parent = obj.superTypes[0];
        if (parent is simpleType) cursor = parent.name;
        else break;
    }
    return false;
}

AType inferExpression(Expression e, map[str, AType] env,
                      map[str, Declaration] objects,
                      map[str, Declaration] methods,
                      Collector c, Tree source) {
    if (e is number) return primitiveType("Int");
    if (e is booleanLiteral) return primitiveType("Bool");
    if (e is charLiteral) return primitiveType("Char");
    if (e is stringLiteral) return primitiveType("String");

    if (e is identifier) {
        if (e.name in env) return env[e.name];
        if (e.name == "print" || e.name == "println")
            return functionType([anyType()], voidType());
        c.report(error(source, "Undefined variable `<e.name>`"));
        return anyType();
    }
    if (e is typeIdentifier) return objectType(e.name);
    if (e is grouped) return inferExpression(e.inner, env, objects, methods, c, source);

    if (e is newObject) {
        AType result = toAType(e.objectType);
        validateTypeArity(result, objects, c, source);
        str name = "";
        list[AType] arguments = [];
        if (result is objectType) name = result.name;
        if (result is genericObjectType) {
            name = result.name;
            arguments = result.arguments;
        }
        if (!(name in objects)) {
            c.report(error(source, "Undefined object `<name>`"));
            return anyType();
        }
        Declaration obj = objects[name];
        if (obj is objectDeclaration) {
            if (size(obj.constructorArgs) != size(e.arguments))
                c.report(error(source, "Constructor `<name>` expects <size(obj.constructorArgs)> arguments, got <size(e.arguments)>"));
            map[str, AType] bindings = genericBindings(name, arguments, objects);
            int n = size(obj.constructorArgs) < size(e.arguments)
                ? size(obj.constructorArgs) : size(e.arguments);
            for (int i <- [0 .. n]) {
                AType actual = inferExpression(e.arguments[i], env, objects, methods, c, source);
                AType expected = substituteType(toAType(obj.constructorArgs[i].parameterType), bindings);
                reportMismatch(c, source, actual, expected, objects);
            }
        }
        for (OverrideDefinition over <- e.overrides) {
            if (!hasMethod(name, over.name, objects, methods)) {
                c.report(error(source, "Cannot override undefined method `<over.name>` in `<name>`"));
            }
            else {
                Declaration inherited = getMethod(name, over.name, objects, methods);
                if (inherited is methodDefinition) {
                    map[str, AType] ownerBindings = genericBindings(name, arguments, objects);
                    if (size(over.parameters) != size(inherited.parameters)) {
                        c.report(error(source,
                            "Override `<over.name>` has incorrect parameter count"));
                    }
                    else {
                        for (int j <- [0 .. size(over.parameters)]) {
                            AType required = substituteType(
                                toAType(inherited.parameters[j].parameterType), ownerBindings);
                            AType supplied = toAType(over.parameters[j].parameterType);
                            if (required != supplied)
                                c.report(error(source,
                                    "Override `<over.name>` changes parameter type <j>"));
                        }
                    }
                    AType requiredReturn = substituteType(
                        declaredTypeOf(inherited.returnTypes), ownerBindings);
                    reportMismatch(c, source, toAType(over.returnType), requiredReturn, objects);
                }
            }
            map[str, AType] overrideEnv = ();
            for (MethodParameter p <- over.parameters)
                overrideEnv[p.name] = toAType(p.parameterType);
            checkBlockSemantics(over.body, overrideEnv, objects, methods,
                c, source, toAType(over.returnType));
        }
        return result;
    }

    if (e is memberAccess) {
        AType ownerType = inferExpression(e.target, env, objects, methods, c, source);
        str ownerName = "";
        if (ownerType is objectType) ownerName = ownerType.name;
        if (ownerType is genericObjectType) ownerName = ownerType.name;
        if (ownerName == "") {
            if (!isUnknown(ownerType)) c.report(error(source, "Cannot access member `<e.name>` on <typeName(ownerType)>"));
            return anyType();
        }
        if (!hasMethod(ownerName, e.name, objects, methods)) {
            c.report(error(source, "Undefined method `<e.name>` in object `<ownerName>`"));
            return anyType();
        }
        Declaration method = getMethod(ownerName, e.name, objects, methods);
        if (method is methodDefinition) {
            list[AType] ownerArgs = [];
            if (ownerType is genericObjectType) ownerArgs = ownerType.arguments;
            map[str, AType] bindings = genericBindings(ownerName, ownerArgs, objects);
            return functionType(
                [substituteType(toAType(p.parameterType), bindings)
                    | MethodParameter p <- method.parameters],
                substituteType(declaredTypeOf(method.returnTypes), bindings));
        }
        return anyType();
    }

    if (e is call) {
        AType callee = inferExpression(e.target, env, objects, methods, c, source);
        list[AType] argTypes = [inferExpression(a, env, objects, methods, c, source)
                                | Expression a <- e.arguments];
        if (callee is functionType) {
            if (size(callee.parameters) != size(argTypes))
                c.report(error(source, "Call expects <size(callee.parameters)> arguments, got <size(argTypes)>"));
            int n = size(callee.parameters) < size(argTypes)
                ? size(callee.parameters) : size(argTypes);
            for (int i <- [0 .. n])
                reportMismatch(c, source, argTypes[i], callee.parameters[i], objects);
            return callee.returnType;
        }
        if (!isUnknown(callee)) c.report(error(source, "Expression is not callable"));
        return anyType();
    }

    if (e is conditional) {
        AType cond = inferExpression(e.condition, env, objects, methods, c, source);
        reportMismatch(c, source, cond, primitiveType("Bool"), objects);
        AType left = inferExpression(e.thenBranch, env, objects, methods, c, source);
        AType right = inferExpression(e.elseBranch, env, objects, methods, c, source);
        if (subtypeOf(left, right, objects)) return right;
        if (subtypeOf(right, left, objects)) return left;
        c.report(error(source, "Conditional branches have incompatible types"));
        return anyType();
    }

    if (e is unaryMinus || e is unaryNeg) {
        AType operand = inferExpression(e.operand, env, objects, methods, c, source);
        AType expected = e is unaryMinus ? primitiveType("Int") : primitiveType("Bool");
        reportMismatch(c, source, operand, expected, objects);
        return expected;
    }

    if (e is range) {
        inferExpression(e.from, env, objects, methods, c, source);
        inferExpression(e.to, env, objects, methods, c, source);
        return anyType();
    }
    if (e is inExpression) {
        inferExpression(e.element, env, objects, methods, c, source);
        inferExpression(e.collection, env, objects, methods, c, source);
        return primitiveType("Bool");
    }

    if (e is addition || e is subtraction || e is multiplication ||
        e is division || e is modulo || e is power || e is lessThan ||
        e is greaterThan || e is lessOrEqual || e is greaterOrEqual ||
        e is equal || e is notEqual || e is logicalAnd || e is logicalOr) {
        AType left = inferExpression(e.left, env, objects, methods, c, source);
        AType right = inferExpression(e.right, env, objects, methods, c, source);
        if (e is logicalAnd || e is logicalOr) {
            reportMismatch(c, source, left, primitiveType("Bool"), objects);
            reportMismatch(c, source, right, primitiveType("Bool"), objects);
            return primitiveType("Bool");
        }
        if (e is equal || e is notEqual) {
            if (!subtypeOf(left, right, objects) && !subtypeOf(right, left, objects))
                c.report(error(source, "Cannot compare incompatible types"));
            return primitiveType("Bool");
        }
        reportMismatch(c, source, left, primitiveType("Int"), objects);
        reportMismatch(c, source, right, primitiveType("Int"), objects);
        if (e is lessThan || e is greaterThan || e is lessOrEqual || e is greaterOrEqual)
            return primitiveType("Bool");
        return primitiveType("Int");
    }

    return anyType();
}

map[str, AType] checkStatementSemantics(Statement stmt, map[str, AType] env,
                map[str, Declaration] objects, map[str, Declaration] methods,
                Collector c, Tree source) {
    if (stmt is valDecl || stmt is varDecl) {
        AType initializer = inferExpression(stmt.expression, env, objects, methods, c, source);
        AType declared = declaredTypeOf(stmt.typeAnnotation);
        validateTypeArity(declared, objects, c, source);
        reportMismatch(c, source, initializer, declared, objects);
        env[stmt.name] = isUnknown(declared) ? initializer : declared;
    }
    else if (stmt is assignmentStmt) {
        AType actual = inferExpression(stmt.expression, env, objects, methods, c, source);
        AType target = inferExpression(stmt.target, env, objects, methods, c, source);
        reportMismatch(c, source, actual, target, objects);
    }
    else if (stmt is exprStmt) {
        inferExpression(stmt.expression, env, objects, methods, c, source);
    }
    else if (stmt is forStmt) {
        AType iterable = inferExpression(stmt.binding.expression, env, objects, methods, c, source);
        map[str, AType] nested = env;
        if (stmt.binding.pattern is idPattern) nested[stmt.binding.pattern.name] = anyType();
        checkStatementSemantics(stmt.body, nested, objects, methods, c, source);
    }
    return env;
}

void checkBlockSemantics(BlockNode block, map[str, AType] initial,
                map[str, Declaration] objects, map[str, Declaration] methods,
                Collector c, Tree source, AType returnType) {
    map[str, AType] env = initial;
    set[str] immutableNames = {};
    list[Tree] statementSources = [];
    if (appl(prod(label("block", _), _, _), _) := source)
        statementSources = getListChildren(source.args[2]);
    for (int i <- [0 .. size(block.statements)]) {
        Statement stmt = block.statements[i];
        Tree stmtSource = i < size(statementSources) ? statementSources[i] : source;
        if (stmt is assignmentStmt && stmt.target is identifier &&
            stmt.target.name in immutableNames)
            c.report(error(stmtSource,
                "Cannot reassign immutable variable `<stmt.target.name>` declared with val"));
        if (i == size(block.statements) - 1 && !isUnknown(returnType) &&
            returnType != voidType() && stmt is exprStmt) {
            AType lastType = inferExpression(stmt.expression, env, objects, methods, c, stmtSource);
            reportMismatch(c, stmtSource, lastType, returnType, objects);
        }
        else env = checkStatementSemantics(stmt, env, objects, methods, c, stmtSource);
        if (stmt is valDecl) immutableNames += {stmt.name};
    }
}

void checkProgramSemantics(Module parsed, Collector c) {
    Program program = convertModuleTree(parsed);
    map[str, Declaration] objects = ();
    map[str, Declaration] methods = ();

    for (Declaration d <- program.declarations) {
        if (d is objectDeclaration) objects[d.name] = d;
        if (d is methodAssignment) methods["<d.targetType>.<d.name>"] = d.methodDef;
    }

    // Validar supertipos, argumentos genericos y ciclos de herencia.
    for (str name <- objects) {
        Declaration obj = objects[name];
        if (obj is objectDeclaration && size(obj.superTypes) > 0) {
            AType parent = toAType(obj.superTypes[0]);
            if (parent is genericObjectType && parent.name in objects) {
                Declaration base = objects[parent.name];
                if (base is objectDeclaration && size(parent.arguments) != size(base.generics))
                    c.report(error(parsed, "Invalid generic arity in parent of `<name>`"));
            }
        }

        set[str] seen = {};
        str cursor = name;
        while (cursor in objects) {
            if (cursor in seen) {
                c.report(error(parsed, "Inheritance cycle involving `<cursor>`"));
                break;
            }
            seen += {cursor};
            Declaration next = objects[cursor];
            if (!(next is objectDeclaration) || size(next.superTypes) == 0) break;
            AType parentType = toAType(next.superTypes[0]);
            if (parentType is objectType) cursor = parentType.name;
            else if (parentType is genericObjectType) cursor = parentType.name;
            else break;
        }
    }

    // Revisar los cuerpos y retornos de los metodos externos.
    for (ModuleItem item <- parsed.items) {
        if (item is methodItem) {
            str key = "<item.methodAssign.targetType>.<item.methodAssign.name>";
            if (key in methods) {
                Declaration method = methods[key];
                if (method is methodDefinition && size(method.bodies) > 0) {
                    map[str, AType] env = ();
                    for (MethodParameter p <- method.parameters) {
                        validateTypeArity(toAType(p.parameterType), objects, c, item.methodAssign);
                        env[p.name] = toAType(p.parameterType);
                    }
                    validateTypeArity(declaredTypeOf(method.returnTypes), objects, c, item.methodAssign);
                    Tree methodBodySource = item.methodAssign;
                    if (appl(regular(opt(_)), [bodyTree]) := item.methodAssign.methodDef.body)
                        methodBodySource = bodyTree;
                    checkBlockSemantics(method.bodies[0], env, objects, methods,
                        c, methodBodySource, declaredTypeOf(method.returnTypes));
                }
            }
        }
    }

    if (program.main is exprStmt && program.main.expression is blockExpression)
        checkBlockSemantics(program.main.expression.block, (), objects, methods,
            c, parsed.main.block, voidType());
}
