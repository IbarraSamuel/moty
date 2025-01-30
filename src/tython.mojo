# from python import Python as py, PythonObject
from collections import Dict, Optional
from collections.string import StringSlice
from sys import argv
import os

alias SymbolTable = Dict[String, String]
alias ArgStr = StringSlice[StaticConstantOrigin]

alias p_args = ["path"]
alias options = ["strict"]
# alias flags = []


struct TypeChecker:
    var symbol_table: SymbolTable
    # var node_visitor: PythonObject

    fn __init__(out self) raises:
        self.symbol_table = SymbolTable()
        # var ast = py.import_module("ast")
        # self.node_visitor = ast.NodeVisitor()


struct Args:
    var path: ArgStr
    var strict: Bool

    fn __init__(out self) raises:
        self = collect_args()

    fn __init__(out self, owned path: ArgStr, owned strict: Bool = True) raises:
        self.path = path
        self.strict = strict


fn collect_args() raises -> Args:
    var argvs = argv()
    var name: Optional[ArgStr] = None
    var opts = Dict[ArgStr, ArgStr]()
    var flags = List[ArgStr]()
    var pos = List[ArgStr]()

    for idx in range(1, len(argvs)):
        print(argvs[idx])
        if argvs[idx].startswith("--"):
            if argvs[idx] not in flags and argvs[idx] not in options:
                os.abort("Invalid Flag Name", argvs[idx])

            if idx + 1 < len(argvs) and argvs[idx] in options:
                name = argvs[idx].lstrip("--")
                continue

            elif argvs[idx] in flags:
                flags.append(argvs[idx].lstrip("--"))
                continue

            else:
                os.abort("Invalid Flag Construction", argvs[idx])
            continue

        if name:
            opts[name.value()] = argvs[idx]
            name = None
            continue

        pos.append(argvs[idx])

    # Path
    path = pos[0]

    # Strict
    strict = Bool(opts.get("strict", "true"))

    return Args(path=path, strict=strict)


fn main() raises:
    var data = Args()
    # var ast = py.import_module("ast")
    with open(data.path, "r") as f:
        code = f.read()
    print(code)
    _ = TypeChecker()
