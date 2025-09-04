from collections import Optional, Dict
from collections.string import StringSlice
from sys import argv
import os, sys

alias ConfigList = List
alias ArgStr = StringSlice[StaticConstantOrigin]


fn contains[
    S: Writable, T: Writable & Movable & Copyable, //, l: ConfigList[T]
](v: S) -> Bool:
    @parameter
    for i in range(len(l)):
        if String(l[i]) == String(v):
            return True

    return False


fn collect_args[
    SC: Writable & Copyable & Movable, //,
    positional: ConfigList[SC],
    arguments: ConfigList[SC],
    flags: ConfigList[SC],
]() -> (List[ArgStr], Dict[ArgStr, ArgStr], List[ArgStr]):
    var argvs = argv()

    var arglen = len(argvs)
    if arglen < 2:
        print("Must provide an argument.")
        sys.exit(1)
    var pos = List[ArgStr]()
    var name: Optional[ArgStr] = None
    var opts = Dict[ArgStr, ArgStr]()
    var flgs = List[ArgStr]()

    for idx in range(1, len(argvs)):
        arg = argvs[idx]
        # Positional (The first arg should not be considered)
        if idx <= len(positional):
            pos.append(arg)
            continue

        # Args & Flags
        if arg.startswith("--"):
            arg = arg.lstrip("--")
            if not contains[flags](arg) and not contains[arguments](arg):
                os.abort(String("Invalid Arg Name: '", arg, "'."))

            if contains[flags](arg):
                flgs.append(arg)
                continue

            if contains[arguments](arg) and idx + 1 < len(argvs):
                name = arg
                continue

            else:
                os.abort(String("Invalid Flag Construction: ", argvs[idx]))
            continue

        if name:
            opts[name.value()] = arg
            name = None
            continue

        os.abort(String("Not valid argument/flag -> ", argvs[idx]))
    return pos, opts, flgs
