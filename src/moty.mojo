import sys

from config import Config, POSITIONAL, LogType
from type_checker import TypeChecker


fn main():
    var config = Config()
    try:
        run(config^)
    except e:
        print("[ERROR]:", e)
        sys.exit(1)


fn run(var config: Config) raises:
    code = config.path.read_text()

    checker = TypeChecker(config)
    errors = checker.run(code)

    for errno, err in enumerate(errors):
        print(errno, ": ", err, sep="")
