module Interpreter


import ObjectlangAST;
import IO;
import List;

void runProgram(Program p) {
    if (moduleProgram(list[Declaration] decls, Statement mainMethod) := p) {
        println("Ejecución iniciada: el programa tiene <size(decls)> declaraciones y un método main.");
    } else {
        println("Ejecutando programa vacío o no reconocido.");
    }
}