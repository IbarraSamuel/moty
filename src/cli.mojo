from collections import Optional, Dict
from collections.string import StringSlice
from sys import argv
import os, sys

alias ArgStr = StaticString


fn collect_args[
    positional: List[StaticString],
    arguments: List[StaticString],
    flags: List[StaticString],
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
            if arg not in flgs and arg not in arguments:
                os.abort(String("Invalid Arg Name: '", arg, "'."))

            if arg in flags:
                flgs.append(arg)
                continue

            if arg in arguments and idx + 1 < len(argvs):
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
