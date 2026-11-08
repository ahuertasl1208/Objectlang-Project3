module Checker

import Structures; 

// Extendemos TypePal para poder agregar tipos y funciones collect
extend analysis::typepal::TypePal;

// pt es el arbol de parseo. Funcion para revisar en caso de errores o retorna vacio.
TModel checkObjectlang(start[Module] pt) {
    // Quitar espacios blancos y comentarios para solo quedarnos con la logica. 
    Tree innerModule = pt has top ? pt.top : pt;
    
    // Anotar clases, funciones y variables que existan y determina que tenga sentido.
    return collectAndSolve(innerModule);
}

