import sys


@fieldwise_init
struct ArgValues:
    var arguments: List[StaticString]
    var options: Dict[StaticString, StaticString]
    var flags: List[StaticString]

    fn __init__(out self):
        self.arguments = {}
        self.options = {}
        self.flags = {}


fn collect_args[
    positional: List[StaticString],
    arguments: List[StaticString],
    flags: List[StaticString],
](out arg_values: ArgValues):
    var argvs = sys.argv()

    var arglen = len(argvs)

    if arglen < 2:
        print("Must provide an argument.")
        sys.exit(1)

    var name: StaticString = ""

    arg_values = ArgValues()

    for idx in range(1, len(argvs)):
        arg = argvs[idx]
        # Positional (The first arg should not be considered)
        if idx <= len(positional):
            arg_values.arguments.append(arg)
            continue

        # Args & Flags
        if arg.startswith("--"):
            arg = arg.lstrip("--")
            if arg not in arg_values.flags and arg not in arguments:
                print("Invalid Arg Name: '", arg, "'.", sep="")
                sys.exit(1)

            if arg in flags:
                arg_values.flags.append(arg)
                continue

            if arg in arguments and idx + 1 < len(argvs):
                name = arg
                continue

            else:
                print(String("Invalid Flag Construction: ", argvs[idx]))
                sys.exit(1)
            continue

        if name != "":
            arg_values.options[name] = arg
            name = ""
            continue

        print(String("Not a valid argument/flag -> `", argvs[idx], "`"))
        sys.exit(1)
