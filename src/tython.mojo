from python import Python as py, PythonObject
from collections import Dict, Optional
from collections.string import StringSlice
from sys import argv

alias SymbolTable = Dict[String, String]


struct TypeChecker:
    var symbol_table: SymbolTable
    var node_visitor: PythonObject

    fn __init__(out self) raises:
        self.symbol_table = SymbolTable()
        var ast = py.import_module("ast")
        self.node_visitor = ast.NodeVisitor()

struct Args:
    var path: StringSlice[StaticConstantOrigin]

    fn __init__(out self):
        self = collect_args()
        

fn collect_args(out args: Args) raises:
    var name: Optional[StringSlice[StaticConstantOrigin]] = None
    for arg in argv():
        if arg.startswith("--"):
            name = arg.lstrip("--")
            continue
        if name:
            if name.unsafe_value() == "path":
                args.path = arg
            name = None
            continue
        raise Error("Missing keys on args collector.")
    while i < len(args):
        alias arg = args[i]
        print(arg)
        if args[i].startswith("--"):
            

fn main() raises:
    alias args = argv()
    i = 0
    while i < len(args):
        if args[i].startswith("--"):
             
    for arg in args:
        print(arg)
    var ast = py.import_module("ast")
    with open("example.py", "r") as f:
        code = f.read()
    tree = ast.parse(code)
    print(tree)
    tt = TypeChecker()
