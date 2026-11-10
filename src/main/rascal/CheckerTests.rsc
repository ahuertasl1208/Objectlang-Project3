module CheckerTests

import Checker;
import Parser;
import ObjectlangAST;

// Ejecutar en Rascal: import CheckerTests; :test
// O ejecutar individualmente test...() desde el REPL.

test bool testEmpty() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/ok/01_empty.ol|)).messages) == 0;

test bool testPrimitives() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/ok/02_primitives.ol|)).messages) == 0;

test bool testInference() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/ok/03_inference_and_operations.ol|)).messages) == 0;

test bool testInheritance() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/ok/04_inheritance_and_constructor.ol|)).messages) == 0;

test bool testCovariance() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/ok/05_generic_covariance.ol|)).messages) == 0;

test bool testMethodAssignment() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/ok/06_method_assignment.ol|)).messages) == 0;

test bool testSnippet3() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/run/snippet3.ol|)).messages) == 0;

test bool testUnknownMethodTarget() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/err/01_unknown_method_target.ol|)).messages) > 0;

test bool testUnknownSupertype() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/err/02_unknown_supertype.ol|)).messages) > 0;

test bool testUnknownConstructorType() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/err/03_unknown_constructor_type.ol|)).messages) > 0;

test bool testMissingGenericArguments() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/err/04_generic_missing_arguments.ol|)).messages) > 0;

test bool testAnnotationMismatch() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/err/05_annotation_mismatch.ol|)).messages) > 0;

test bool testVarianceViolation() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/err/06_covariance_violation.ol|)).messages) > 0;

test bool testUnknownNestedType() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/err/07_unknown_nested_generic_type.ol|)).messages) > 0;

test bool testUnknownVariableType() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/err/08_unknown_variable_type.ol|)).messages) > 0;

test bool testUnknownMethodCall() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/err/09_unknown_method_call.ol|)).messages) > 0;

test bool testConstructorArgumentType() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/err/10_constructor_argument_type.ol|)).messages) > 0;

test bool testMethodArgumentType() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/err/11_wrong_method_argument.ol|)).messages) > 0;

test bool testImmutableReassignment() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/err/12_immutable_reassignment.ol|)).messages) > 0;

test bool testInheritanceCycle() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/err/13_inheritance_cycle.ol|)).messages) > 0;

test bool testOverrideSignature() =
    size(checkObjectlang(parseObjectlang(
        |project://objectlang-project3/examples/types/err/14_override_signature.ol|)).messages) > 0;
