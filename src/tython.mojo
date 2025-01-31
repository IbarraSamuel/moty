# from python import Python as py, PythonObject
from collections import Dict
from cli import Config, ArgStr

alias SymbolTable = Dict[String, String]


struct TypeChecker:
    var symbol_table: SymbolTable
    # var node_visitor: PythonObject

    fn __init__(out self) raises:
        self.symbol_table = SymbolTable()
        # var ast = py.import_module("ast")
        # self.node_visitor = ast.NodeVisitor()


fn main() raises:
    var config = Config()
    print(config)
    with open(config.path, "r") as f:
        code = f.read()
    print(code)
    _ = TypeChecker()
