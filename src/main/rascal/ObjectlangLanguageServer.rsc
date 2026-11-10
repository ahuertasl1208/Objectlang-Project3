module ObjectlangLanguageServer

import Structures;
import ParseTree;
import Parser;
import Checker;
import Message;
import util::LanguageServer;
import util::Reflective;

// Publicar los errores del Checker como diagnosticos en el editor.
Summary analyzeObjectlang(loc origin, Tree input) {
    if (start[Module] parsed := input) {
        TModel model = checkObjectlang(parsed);
        rel[loc, Message] diagnostics = {
            <message.at, message> | Message message <- model.messages
        };
        return summary(origin, messages=diagnostics);
    }

    return summary(origin);
}

// Servicios que ofreceremos a VS Code.
set[LanguageService] objectlangServices() = {
    parsing(
        parser(
            #start[Module],
            allowAmbiguity=true,
            filters={resolveLayoutAmbiguity}
        )
    ),
    analysis(
        analyzeObjectlang,
        providesDocumentation=false,
        providesDefinitions=false,
        providesReferences=false,
        providesImplementations=false
    )
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
