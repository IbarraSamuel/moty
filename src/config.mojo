from collections.string import StringSlice
from collections import Dict
from cli import collect_args
from pathlib import Path

alias ArgStr = StringSlice[StaticConstantOrigin]

alias POSITIONAL = ["path"]
alias ARGUMENTS = ["log-type"]
alias FLAGS = ["strict"]


@register_passable("trivial")
struct LogType(EqualityComparable, Writable):
    alias silent = LogType(1)
    alias verbose = LogType(2)
    var _v: Int

    fn __init__(out self, v: Int):
        self._v = v

    @implicit
    fn __init__(out self, v: ArgStr):
        self = LogType.silent
        if v == "verbose":
            self = LogType.verbose

    fn __eq__(self, other: Self) -> Bool:
        return self._v == other._v

    fn __ne__(self, other: Self) -> Bool:
        return not (self == other)

    fn write_to[W: Writer](self, mut w: W):
        s = "silent"
        if self == Self.verbose:
            s = "verbose"
        w.write("LogType(", s, ")")


struct Config(Writable):
    # Positional
    var path: Path
    # Arguments
    var log_type: LogType
    # Flags
    var strict: Bool

    fn __init__(out self):
        pos, opt, flags = collect_args[POSITIONAL, ARGUMENTS, FLAGS]()
        self = Self(pos, opt, flags)
        if self.log_type == self.log_type.verbose:
            print(self)

    fn __init__(
        out self,
        pos: List[ArgStr],
        opt: Dict[ArgStr, ArgStr],
        flags: List[ArgStr],
    ):
        # Path
        self.path = Path(pos[0])

        # Log Type
        self.log_type = opt.get("log-type", "silent")

        # Strict
        self.strict = "strict" in flags

    fn write_to[W: Writer](self, mut w: W):
        w.write(
            "Config(path=",
            self.path,
            ", log-type=",
            self.log_type,
            ", strict=",
            self.strict,
            ")",
        )
