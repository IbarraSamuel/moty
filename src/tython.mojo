# from python import Python as py, PythonObject
from collections import Dict
from config import Config, POSITIONAL
from type_checker import TypeChecker


fn main() raises:
    var config = Config()

    with open(config.path, "r") as f:
        code = f.read()

    if config.log_type == config.log_type.verbose:
        print(code)

    checker = TypeChecker(config)
    errors = checker.run(code)

    for err in range(len(errors)):
        print(err, ":", errors[err])
