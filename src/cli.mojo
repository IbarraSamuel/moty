from collections import Optional, Dict
from collections.string import StringSlice
from sys import argv
import os

alias ArgStr = StringSlice[StaticConstantOrigin]

alias POSITIONAL = ["path"]
alias ARGUMENTS = ["values"]
alias FLAGS = ["strict"]


struct Config(Writable):
    var path: ArgStr
    var rules: ArgStr
    var strict: Bool

    fn __init__(out self) raises:
        pos, opt, flags = collect_args()

        # Path
        self.path = pos[0]

        # Rules
        self.rules = opt.get("rules", "all")

        # Strict
        self.strict = "strict" in flags

    fn write_to[W: Writer](self, mut w: W):
        w.write(
            "Config(path=",
            self.path,
            ", rules=",
            self.rules,
            ", strict=",
            self.strict,
            ")",
        )


fn collect_args() -> (List[ArgStr], Dict[ArgStr, ArgStr], List[ArgStr]):
    var argvs = argv()
    var pos = List[ArgStr]()
    var name: Optional[ArgStr] = None
    var opts = Dict[ArgStr, ArgStr]()
    var flags = List[ArgStr]()

    for idx in range(1, len(argvs)):
        arg = argvs[idx]
        # Positional (The first arg should not be considered)
        if idx <= len(POSITIONAL):
            pos.append(arg)
            continue

        # Args & Flags
        if arg.startswith("--"):
            arg = arg.lstrip("--")
            if arg not in FLAGS and arg not in ARGUMENTS:
                os.abort("Invalid Flag Name", arg)

            if arg in FLAGS:
                flags.append(arg)
                continue

            if arg in ARGUMENTS and idx + 1 < len(argvs):
                name = arg
                continue

            else:
                os.abort("Invalid Flag Construction", argvs[idx])
            continue

        if name:
            opts[name.value()] = arg
            name = None
            continue

        os.abort("Not valid argument/flag ->", argvs[idx])
    return pos, opts, flags
