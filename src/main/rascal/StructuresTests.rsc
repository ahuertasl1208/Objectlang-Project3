module StructuresTests

import StructuresConverter;
import ParseTree;
import ObjectlangAST;
import Node;
import Exception;

// Mismo estilo de limpieza de tu compañero
Program cleanAST(Program p) {
    return unsetRec(p);
}

// Función auxiliar para pruebas negativas
bool rejectsProgram(str input) {
    try {
        convertProgram(input);
        return false;
    } catch ParseError(_): {
        return true;
    }
}

// ==========================================
// PRUEBAS DE CONSTRUCTORES Y RECHAZO SINTÁCTICO
// ==========================================

test bool testNewWithoutParens() =
    moduleProgram(
        [],
        exprStmt(blockExpression(blockNode([
            valDecl(
                "myPuppy",
                [],
                newObject(simpleType("Puppy"), [], [])
            )
        ])))
    ) == cleanAST(
        convertProgram("method main { val myPuppy = new Puppy }")
    );

test bool testRejectObjectAnimal() = 
    rejectsProgram("objectAnimal method main { }");

test bool testRejectMethodMain() = 
    rejectsProgram("methodmain { }");

/// val con primitivo
test bool testValPrimitive() =
    cleanAST(convertProgram("method main { val x : Int = 5 }")) ==
    moduleProgram([], 
        exprStmt(blockExpression(blockNode([
            valDecl("x", [tInt()], number(5))
        ])))
    );

// Parámetro de método con primitivo
test bool testMethodParamPrimitive() =
    cleanAST(convertProgram("object Foo Foo.bar = method (x : Bool) : String method main { }")) ==
    moduleProgram([
        objectDeclaration("Foo", [], [], []),
        methodAssignment("Foo", "bar", 
            methodDefinition([methodParameter("x", tBool())], [tString()], [])
        )
    ], 
        exprStmt(blockExpression(blockNode([])))
    );

// Parámetro de constructor con primitivo
test bool testConstructorParamPrimitive() =
    cleanAST(convertProgram("object P(val n : Char) method main { }")) ==
    moduleProgram([
        objectDeclaration("P", [], [], [
            constructorParameter("val", "n", tChar())
        ])
    ], 
        exprStmt(blockExpression(blockNode([])))
    );

// Genérico con primitivo
test bool testGenericPrimitive() =
    cleanAST(convertProgram("method main { val l : List[String] = x }")) ==
    moduleProgram([], 
        exprStmt(blockExpression(blockNode([
            valDecl("l", [genericType("List", [tString()])], identifier("x"))
        ])))
    );
// ==========================================
// PRUEBAS POSITIVAS (Aserciones exactas de AST)
// ==========================================

test bool testObjectFoo() =
    moduleProgram(
        [objectDeclaration("Foo", [], [], [])],
        exprStmt(blockExpression(blockNode([]))) 
    ) == cleanAST(convertProgram("object Foo() method main { }"));

test bool testPrintX() =
    moduleProgram(
        [],
        exprStmt(blockExpression(blockNode([
            exprStmt(call(identifier("print"), [identifier("x")]))
        ])))
    ) == cleanAST(convertProgram("method main { print(x) }"));

test bool testDosLlamadas() =
    moduleProgram(
        [],
        exprStmt(blockExpression(blockNode([
            exprStmt(call(identifier("f"), [identifier("x")])),
            exprStmt(call(identifier("g"), [identifier("y")]))
        ])))
    ) == cleanAST(convertProgram("method main { f(x)\n g(y) }"));

test bool testNewDog() =
    moduleProgram(
        [],
        exprStmt(blockExpression(blockNode([
            valDecl("d", [], newObject(simpleType("Dog"), [], []))
        ])))
    ) == cleanAST(convertProgram("method main { val d = new Dog() }"));

test bool testNewPuppy() =
    moduleProgram(
        [],
        exprStmt(blockExpression(blockNode([
            valDecl("p", [], newObject(simpleType("Puppy"), [], []))
        ])))
    ) == cleanAST(convertProgram("method main { val p = new Puppy() }"));

test bool testForStmt() =
    moduleProgram(
        [],
        exprStmt(blockExpression(blockNode([
            forStmt(
                forBinding(idPattern("x"), "\<-", identifier("xs")),
                exprStmt(call(identifier("print"), [identifier("x")]))
            )
        ])))
    ) == cleanAST(convertProgram("method main { for (x \<- xs) print(x) }"));

// ==========================================
// REGRESIÓN: BLOQUES Y SEPARADORES
// ==========================================

// Bloque vacío con múltiples saltos de línea.
test bool testEmptyBlockWithNewlines() =
    moduleProgram(
        [],
        exprStmt(blockExpression(blockNode([])))
    ) == cleanAST(
        convertProgram("method main {\n\n}")
    );

// Dos sentencias separadas por líneas en blanco.
test bool testStatementsWithBlankLines() =
    moduleProgram(
        [],
        exprStmt(blockExpression(blockNode([
            exprStmt(call(identifier("f"), [identifier("x")])),
            exprStmt(call(identifier("g"), [identifier("y")]))
        ])))
    ) == cleanAST(
        convertProgram("method main {\n\nf(x)\n\ng(y)\n\n}")
    );

// Dos sentencias no pueden separarse solamente por espacios.
test bool testRejectStatementsWithoutNewline() =
    rejectsProgram("method main { f(x) g(y) }");

// Block no puede utilizarse como una expresión arbitraria.
test bool testRejectBlockAsExpression() =
    rejectsProgram("method main { val x = {5} }");


// ==========================================
// REGRESIÓN: CONSTRUCTORES
// ==========================================

// Constructores anidados y expresiones como argumentos.
test bool testNestedConstructors() =
    moduleProgram(
        [],
        exprStmt(blockExpression(blockNode([
            valDecl(
                "p",
                [],
                newObject(
                    simpleType("Persona"),
                    [
                        newObject(simpleType("Direccion"), [], []),
                        addition(number(5), number(2))
                    ],
                    []
                )
            )
        ])))
    ) == cleanAST(
        convertProgram(
            "method main { val p = new Persona(new Direccion(), 5 + 2) }"
        )
    );


// ==========================================
// REGRESIÓN: CICLOS FOR
// ==========================================

// For con patrón de tupla.
test bool testForWithTuplePattern() =
    moduleProgram(
        [],
        exprStmt(blockExpression(blockNode([
            forStmt(
                forBinding(
                    tuplePattern("name", ["rating"]),
                    "\<-",
                    identifier("ratings")
                ),
                exprStmt(
                    call(identifier("print"), [identifier("name")])
                )
            )
        ])))
    ) == cleanAST(
        convertProgram(
            "method main { for ((name, rating) \<- ratings) print(name) }"
        )
    );

// Una expresión puede continuar en la siguiente línea.
test bool testMultilineExpression() =
    moduleProgram(
        [],
        exprStmt(blockExpression(blockNode([
            valDecl(
                "resultado",
                [],
                addition(number(5), number(3))
            )
        ])))
    ) == cleanAST(
        convertProgram("method main { val resultado = 5 +\n 3 }")
    );

// REGRESIÓN: saltos finales de bloque y comentarios

test bool testBlockWithTrailingNewline() =
    moduleProgram(
        [],
        exprStmt(blockExpression(blockNode([
            valDecl("x", [], number(5))
        ])))
    ) == cleanAST(
        convertProgram("method main {\nval x = 5\n}")
    );

test bool testBlockWithCommentBeforeStatement() =
    moduleProgram(
        [],
        exprStmt(blockExpression(blockNode([
            valDecl("x", [], number(5))
        ])))
    ) == cleanAST(
        convertProgram("method main {\n// comentario\nval x = 5\n}")
    );