module ObjectlangLanguageServer

import Structures;
import ParseTree;
import util::LanguageServer;
import util::Reflective;

// Servicios que ofreceremos a VS Code.
set[LanguageService] objectlangServices() = {
    parsing(parser(#start[Module]))
};

// Registrar archivos .objl como programas Objectlang.
void main() {
    registerLanguage(
        language(
            getProjectPathConfig(
                |project://objectlang-project3|,
                mode=interpreter_external()
            ),
            "Objectlang",
            {"objl"},
            "ObjectlangLanguageServer",
            "objectlangServices"
        )
    );
}