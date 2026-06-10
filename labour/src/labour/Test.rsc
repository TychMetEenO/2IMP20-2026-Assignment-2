module labour::Test

/*
 * Headless test runner: the same tests as Plugin::runTests, but without the
 * VS Code/LSP dependency, so the whole pipeline can be exercised from a
 * plain Rascal shell. Run from the project root directory with:
 *
 *   java -cp <rascal.jar> org.rascalmpl.shell.RascalShell labour::Test
 *
 * Test programs live in three directories:
 *  - test/valid:          must parse and pass the well-formedness checker
 *  - test/invalid:        must parse but fail the well-formedness checker
 *  - test/syntax-invalid: must already be rejected by the parser
 */

import IO;
import Exception;

import labour::Parser;
import labour::CST2AST;
import labour::Check;

bool checkFile(loc file)
  = checkBoulderWallConfiguration(cst2ast(parseLaBouR(file)));

int main(list[str] _ = []) {
  fails = 0;
  validFiles = |cwd:///test/valid|.ls;
  invalidFiles = |cwd:///test/invalid|.ls;
  syntaxInvalidFiles = |cwd:///test/syntax-invalid|.ls;

  println("\nValid tests");
  for (file <- validFiles) {
    if (checkFile(file)) {
      println("SUCCESS: <file.path> returns true");
    } else {
      println("FAILURE: <file.path> returns false");
      fails += 1;
    }
  }

  println("\nInvalid tests");
  for (file <- invalidFiles) {
    if (checkFile(file)) {
      println("FAILURE: <file.path> returns true");
      fails += 1;
    } else {
      println("SUCCESS: <file.path> returns false");
    }
  }

  println("\nSyntax-invalid tests (programs the parser must reject)");
  for (file <- syntaxInvalidFiles) {
    try {
      parseLaBouR(file);
      println("FAILURE: <file.path> parses, but it should be a parse error");
      fails += 1;
    } catch ParseError(_): {
      println("SUCCESS: <file.path> is rejected by the parser");
    }
  }

  println("\n<fails> failed tests");
  return fails;
}
