module Main

import ParseTree;
import IO;
import Message;       
import Exception;    
import List;

// Importa la gramática para que parse() funcione
import Expressions;
import Structures;

import ObjectlangAST;
import StructuresConverter;
import Interpreter;
import Checker;
import Parser;

void runObjectlang(loc fileLoc) {
    try {
        // Parseo directo desde el loc (conserva línea/columna)
        start[Module] pt = parseObjectlang(fileLoc);
        
        // Chequeo
        list[Message] errors = [m | m <- checkObjectlang(pt).messages, m is error];
        
        if (size(errors) > 0) {
            println("Se encontraron errores estáticos. Ejecución detenida:");
            for (Message e <- errors) {
                println("- <e.msg> en <e.at>");
            }
            return;
        }
        
        // Conversión al AST usando la raíz desempacada
        Program ast = convertModuleTree(pt.top);
        
        // Ejecución
        runProgram(ast);

    } catch ParseError(loc l): {
        println("Error de sintaxis en <l.file> (Línea <l.begin.line>, Columna <l.begin.column>)");
    } catch str problema: {
        println("Error: <problema>");
    }
}

