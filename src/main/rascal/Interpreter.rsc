module Interpreter

import ObjectlangAST; 
import IO;
import String;
import List;

// Los valores de ejecución
data Value
  = intV(int n)
  | boolV(bool b)
  | charV(str c)
  | stringV(str s)
  | rangeV(int from, int to)
  | objectV(str typeName, map[str, Value] fields, map[str, OverrideDefinition] overrides)
  ;

// El entorno
alias Env = map[str, Value];

// Tablas globales del programa: definiciones de objetos y métodos asignados
map[str, Declaration] objectTable = ();
map[str, map[str, Declaration]] methodTable = ();

void runProgram(moduleProgram(list[Declaration] decls, Statement main)) {
    objectTable = ();
    methodTable = ();
    for (Declaration d <- decls) register(d);
    exec(main, ());
}

void register(decl:objectDeclaration(str name, _, _, _)) {
    objectTable[name] = decl;
}

void register(methodAssignment(str target, str name, Declaration def)) {
    methodTable[target] = (methodTable[target] ? ()) + (name : def);
}
// toText: Representación textual
str toText(intV(int n)) = "<n>";
str toText(boolV(bool b)) = "<b>";
str toText(charV(str c)) = c;
str toText(stringV(str s)) = s;
str toText(rangeV(int a, int b)) = "<a> -\> <b>";
str toText(objectV(str t, _, _)) = t;

// print y println
Value eval(call(identifier("print"), [Expression arg]), Env env) {
    str text = toText(eval(arg, env));
    print(text);
    return stringV(text);
}

Value eval(call(identifier("println"), [Expression arg]), Env env) {
    str text = toText(eval(arg, env));
    println(text);
    return stringV(text);
}

// Despacho por patrones
Value eval(number(int n), Env env) = intV(n);
Value eval(booleanLiteral(bool b), Env env) = boolV(b);
Value eval(charLiteral(str c), Env env) = charV(c);

// Variables y Errores de ejecución 
Value eval(identifier(str name), Env env) {
    if (name in env) return env[name];
    throw "Variable no definida: <name>";
}




// Aritméticos 
Value eval(addition(Expression l, Expression r), Env env) = intV(x + y) when intV(x) := eval(l, env), intV(y) := eval(r, env);
Value eval(subtraction(Expression l, Expression r), Env env) = intV(x - y) when intV(x) := eval(l, env), intV(y) := eval(r, env);
Value eval(multiplication(Expression l, Expression r), Env env) = intV(x * y) when intV(x) := eval(l, env), intV(y) := eval(r, env);

Value eval(division(Expression l, Expression r), Env env) {
    if (intV(x) := eval(l, env), intV(y) := eval(r, env)) {
        if (y == 0) throw "División por cero";
        return intV(x / y);
    }
    throw "La división espera dos enteros";
}

Value eval(modulo(Expression l, Expression r), Env env) {
    if (intV(x) := eval(l, env), intV(y) := eval(r, env)) {
        if (y == 0) throw "Módulo por cero";
        return intV(x % y);
    }
    throw "El módulo espera dos enteros";
}

Value eval(power(Expression l, Expression r), Env env) {
    if (intV(base) := eval(l, env), intV(exp) := eval(r, env)) {
        if (exp < 0) throw "El exponente no puede ser negativo";
        return intV(intPower(base, exp));
    }
    throw "La potencia espera dos enteros";
}

int intPower(int base, int exp) = exp == 0 ? 1 : base * intPower(base, exp - 1);

Value eval(unaryMinus(Expression e), Env env) = intV(-x) when intV(x) := eval(e, env);

// Comparaciones
Value eval(lessThan(Expression l, Expression r), Env env) = boolV(x < y) when intV(x) := eval(l, env), intV(y) := eval(r, env);
Value eval(greaterThan(Expression l, Expression r), Env env) = boolV(x > y) when intV(x) := eval(l, env), intV(y) := eval(r, env);
Value eval(lessOrEqual(Expression l, Expression r), Env env) = boolV(x <= y) when intV(x) := eval(l, env), intV(y) := eval(r, env);
Value eval(greaterOrEqual(Expression l, Expression r), Env env) = boolV(x >= y) when intV(x) := eval(l, env), intV(y) := eval(r, env);
Value eval(equal(Expression l, Expression r), Env env) = boolV(eval(l, env) == eval(r, env));
Value eval(notEqual(Expression l, Expression r), Env env) = boolV(eval(l, env) != eval(r, env));

// Lógicos (con cortocircuito) 
Value eval(logicalAnd(Expression l, Expression r), Env env) {
    Value left = eval(l, env);
    if (boolV(false) := left) return boolV(false);
    if (boolV(true) := left, boolV(b) := eval(r, env)) return boolV(b);
    throw "\'and\' espera dos booleanos";
}

Value eval(logicalOr(Expression l, Expression r), Env env) {
    Value left = eval(l, env);
    if (boolV(true) := left) return boolV(true);
    if (boolV(false) := left, boolV(b) := eval(r, env)) return boolV(b);
    throw "\'or\' espera dos booleanos";
}

Value eval(unaryNeg(Expression e), Env env) = boolV(!b) when boolV(b) := eval(e, env);

Value eval(grouped(Expression inner), Env env) = eval(inner, env);

// Objetos
str typeNameOf(simpleType(str n)) = n;
str typeNameOf(genericType(str n, _)) = n;   // los genéricos se borran en ejecución
default str typeNameOf(TypeNode t) { throw "No se pueden crear objetos de un tipo primitivo"; }

Value eval(newObject(TypeNode t, list[Expression] args, list[OverrideDefinition] overrides), Env env) {
    str name = typeNameOf(t);
    if (name in objectTable, objectDeclaration(_, _, _, list[ConstructorParameter] params) := objectTable[name]) {
        list[Value] argValues = [eval(a, env) | a <- args];
        if (size(params) != size(argValues)) {
            throw "<name> espera <size(params)> argumentos y recibió <size(argValues)>";
        }
        map[str, Value] fields = (params[i].name : argValues[i] | i <- [0..size(params)]);
        map[str, OverrideDefinition] ovs = (ov.name : ov | ov <- overrides);
        return objectV(name, fields, ovs);
    }
    throw "Objeto no definido: <name>";
}

// Acceso a un campo: obj.campo
Value eval(memberAccess(Expression target, str field), Env env) {
    if (objectV(str t, map[str, Value] fields, _) := eval(target, env)) {
        if (field in fields) return fields[field];
        throw "El objeto <t> no tiene el campo <field>";
    }
    throw "Solo se puede acceder a campos de un objeto: <field>";
}

// Llamada a un método: obj.metodo(args)
Value eval(call(memberAccess(Expression target, str m), list[Expression] args), Env env) {
    if (objectV(str t, map[str, Value] fields, map[str, OverrideDefinition] overrides) := eval(target, env)) {
        list[Value] argValues = [eval(a, env) | a <- args];
        if (m in overrides, overrideDefinition(_, list[MethodParameter] ps, _, BlockNode body) := overrides[m]) {
            return invoke(t, m, ps, body, fields, argValues);
        }
        if (methodDefinition(list[MethodParameter] ps, _, list[BlockNode] bodies) := findMethod(t, m)) {
            if (bodies == []) throw "El método <t>.<m> es abstracto y no tiene implementación";
            return invoke(t, m, ps, bodies[0], fields, argValues);
        }
    }
    throw "Solo se pueden llamar métodos sobre objetos: <m>";
}

Declaration findMethod(str typeName, str m) {
    if (typeName in methodTable, m in methodTable[typeName]) return methodTable[typeName][m];
    if (typeName in objectTable, objectDeclaration(_, _, [TypeNode sup], _) := objectTable[typeName]) {
        return findMethod(typeNameOf(sup), m);
    }
    throw "Método no encontrado: <typeName>.<m>";
}

// Dentro del método se ven los campos del objeto y los parámetros.
Value invoke(str t, str m, list[MethodParameter] ps, BlockNode body, map[str, Value] fields, list[Value] argValues) {
    if (size(ps) != size(argValues)) {
        throw "<t>.<m> espera <size(ps)> argumentos y recibió <size(argValues)>";
    }
    Env methodEnv = fields + (ps[i].name : argValues[i] | i <- [0..size(ps)]);
    return eval(blockExpression(body), methodEnv);
}

// Rangos (inclusivos)
Value eval(range(Expression l, Expression r), Env env) = rangeV(x, y) when intV(x) := eval(l, env), intV(y) := eval(r, env);

Value eval(inExpression(Expression e, Expression c), Env env) {
    if (intV(x) := eval(e, env), rangeV(a, b) := eval(c, env)) return boolV(a <= x && x <= b);
    throw "\'in\' espera un entero y un rango";
}

Value eval(conditional(Expression cond, Expression thn, Expression els), Env env) {
    if (boolV(true) := eval(cond, env)) return eval(thn, env);
    return eval(els, env);
}


// Strings y su interpolación
Value eval(stringLiteral(list[StringPart] parts), Env env) {
    str result = "";
    for (p <- parts) {
        if (textPart(str text) := p) result += text;
        else if (escapePart(str esc) := p) {
            switch(esc) {
                case "\\n": result += "\n";
                case "\\t": result += "\t";
                case "\\r": result += "\r";
                case "\\\"": result += "\"";
                case "\\$": result += "$";
                case "\\\\": result += "\\";
                default: result += esc;
            }
        }
        else if (identifierInterpolation(str name) := p) result += toText(eval(identifier(name), env));
        else if (expressionInterpolation(Expression e) := p) result += toText(eval(e, env));
    }
    return stringV(result);
}

// El bloque y el main
Value eval(blockExpression(blockNode(list[Statement] stmts)), Env env) {
    Value lastVal = intV(0); // Por si el bloque está vacío
    Env currentEnv = env;
    for (s <- stmts) {
        tuple[Value, Env] res = exec(s, currentEnv);
        lastVal = res[0];
        currentEnv = res[1]; // Actualizamos el entorno para la siguiente sentencia
    }
    return lastVal;
}

// Ejecución de Sentencias 
tuple[Value, Env] exec(valDecl(str name, _, Expression expr), Env env) {
    Value v = eval(expr, env);
    return <v, env + (name : v)>; // Se agrega el nombre al entorno

}

tuple[Value, Env] exec(varDecl(str name, _, Expression expr), Env env) {
    Value v = eval(expr, env);
    return <v, env + (name : v)>;
}

// Asignación
tuple[Value, Env] exec(assignmentStmt(identifier(str name), Expression expr), Env env) {
    if (name notin env) throw "Variable no definida: <name>";
    Value v = eval(expr, env);
    return <v, env + (name : v)>;
}

// Ciclo for sobre rangos 
// El cuerpo puede modificar variables de afuera, pero lo que declara
// adentro (incluida la variable del ciclo) no sale del ciclo.
tuple[Value, Env] exec(forStmt(forBinding(idPattern(str name), _, Expression expr), Statement body), Env env) {
    if (rangeV(int a, int b) := eval(expr, env)) {
        Env current = env;
        list[int] values = a <= b ? [a..b + 1] : [];
        for (int i <- values) {
            tuple[Value, Env] res = exec(body, current + (name : intV(i)));
            Env updated = (k : res[1][k] | k <- current, k != name);
            if (name in current) updated[name] = current[name];
            current = updated;
        }
        return <intV(0), current>;
    }
    throw "El for espera un rango";
}

tuple[Value, Env] exec(forStmt(forBinding(tuplePattern(_, _), _, _), _), Env env) {
    throw "Patrón de tupla no soportado en ejecución";
}


tuple[Value, Env] exec(exprStmt(Expression expr), Env env) {
    Value v = eval(expr, env);
    return <v, env>;
}

// Casos por defecto para capturar errores de AST
default Value eval(Expression e, Env env) {
    throw "Falta implementar evaluación para: <e>";
}
default tuple[Value, Env] exec(Statement s, Env env) {
    throw "Falta implementar ejecución para: <s>";
}