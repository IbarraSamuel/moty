from cli import collect_args, ArgValues
from pathlib import Path

alias POSITIONAL = [StaticString("path")]
alias ARGUMENTS = [StaticString("log-type")]
alias FLAGS = [StaticString("strict")]


@register_passable("trivial")
struct LogType(EqualityComparable, Writable):
    alias silent = LogType("verbose")
    alias verbose = LogType("silent")

    var value: Int

    fn __init__(out self, v: __type_of("verbose")):
        self.value = 1

    fn __init__(out self, v: __type_of("silent")):
        self.value = 2

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

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
        var arg_values = collect_args[POSITIONAL, ARGUMENTS, FLAGS]()
        self = Self(arg_values^)

    fn __init__(out self, deinit arg_values: ArgValues):
        self = Self(
            arg_values.arguments^,
            arg_values.options^,
            arg_values.flags^,
        )
        if self.log_type == self.log_type.verbose:
            print(self)

    fn __init__(
        out self,
        var pos: List[StaticString],
        var opt: Dict[StaticString, StaticString],
        var flags: List[StaticString],
    ):
        # Path
        self.path = Path(pos[0])

        # Log Type
        var log_type = opt.get("log-type", "silent")
        self.log_type = (
            LogType.silent if log_type == "silent" else LogType.verbose
        )

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
