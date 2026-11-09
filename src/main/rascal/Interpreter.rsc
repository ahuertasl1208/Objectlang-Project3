module Interpreter

import ObjectlangAST; 
import IO;
import String;

// Los valores de ejecución
data Value
  = intV(int n)
  | boolV(bool b)
  | charV(str c)
  | stringV(str s)
  ;

// El entorno
alias Env = map[str, Value];

void runProgram(moduleProgram(_, Statement main)) {
    exec(main, ());
}

// toText: Representación textual
str toText(intV(int n)) = "<n>";
str toText(boolV(bool b)) = "<b>";
str toText(charV(str c)) = c;
str toText(stringV(str s)) = s;

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