module Parser

import ParseTree;
import Structures;
import Node;
import List;
import Set;

// Punto de entrada único para parsear programas Objectilang.
start[Module] parseObjectlang(loc file)
    = checkNoAmbiguity(parse(#start[Module], file, allowAmbiguity=true, filters={resolveLayoutAmbiguity}));

start[Module] parseObjectlang(str source)
    = checkNoAmbiguity(parse(#start[Module], source, allowAmbiguity=true, filters={resolveLayoutAmbiguity}));

// Filtro de desambiguación: si todas las alternativas de un nodo ambiguo
// son iguales cuando se ignora el layout, solo difieren en dónde quedó
// un espacio, un salto de línea o un comentario. Se conserva una sola.
Tree resolveLayoutAmbiguity(amb(set[Tree] alternatives)) {
    list[Tree] options = toList(alternatives);
    node reference = withoutLayout(options[0]);
    if (all(Tree other <- options, withoutLayout(other) == reference)) {
        return options[0];
    }
    fail;
}

// Si quedó una ambigüedad que no es de layout, es un error real de la gramática.
start[Module] checkNoAmbiguity(start[Module] tree) {
    if (/a:amb(_) := tree) {
        throw "Ambigüedad real en la gramática: <unparse(a)>";
    }
    return tree;
}

// Copia del árbol con el layout vaciado y sin ubicaciones,
// para comparar solo la estructura.
node withoutLayout(Tree t)
    = unsetRec(visit (t) { case appl(p:prod(layouts(_), _, _), _) => appl(p, []) });