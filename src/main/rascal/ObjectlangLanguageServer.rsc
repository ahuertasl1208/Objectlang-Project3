module ObjectlangLanguageServer

import Structures;
import ParseTree;
import util::LanguageServer;
import util::Reflective;

// Servicios que ofreceremos a VS Code.
set[LanguageService] objectlangServices() = {
    parsing(parser(#start[Module]))
};

// Registrar archivos .ol como programas Objectlang.
void main() {
    registerLanguage(
        language(
            getProjectPathConfig(
                |project://objectlang-project3|,
                mode=interpreter_external()
            ),
            "Objectlang",
            {"ol"},
            "ObjectlangLanguageServer",
            "objectlangServices"
        )
    );
}