from collections import Optional, Dict
from collections.string import StringSlice
from sys import argv
import os

alias ConfigList = ListLiteral
alias ArgStr = StringSlice[StaticConstantOrigin]


fn contains[
    S: Writable, T: WritableCollectionElement, //, l: ListLiteral[T]
](v: S) -> Bool:
    @parameter
    for i in range(len(l)):
        if String(l.get[i, T]()) == String(v):
            return True

    return False


fn collect_args[
    SC: WritableCollectionElement, //,
    positional: ConfigList[SC],
    arguments: ConfigList[SC],
    flags: ConfigList[SC],
]() -> (List[ArgStr], Dict[ArgStr, ArgStr], List[ArgStr]):
    var argvs = argv()
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
                os.abort("Invalid Arg Name: '", arg, "'.")

            if contains[flags](arg):
                flgs.append(arg)
                continue

            if contains[arguments](arg) and idx + 1 < len(argvs):
                name = arg
                continue

            else:
                os.abort("Invalid Flag Construction: ", argvs[idx])
            continue

        if name:
            opts[name.value()] = arg
            name = None
            continue

        os.abort("Not valid argument/flag -> ", argvs[idx])
    return pos, opts, flgs
