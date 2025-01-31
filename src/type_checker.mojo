from python import PythonObject, Python as py
from collections import Dict


struct NodeVisitor:
    # TODO: This needs to be implemented without using inheritance.
    pass


struct TypeChecker:
    var visitor: NodeVisitor
    pass


fn parse_code(code: String) raises -> PythonObject:
    ast = py.import_module("ast")
    return ast.parse(code)
