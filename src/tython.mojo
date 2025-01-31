# from python import Python as py, PythonObject
from collections import Dict
from cli import Config, ArgStr
from type_checker import TypeChecker


fn main() raises:
    var config = Config()
    with open(config.path, "r") as f:
        code = f.read()

    print(code)

    checker = TypeChecker()
    errors = checker.run(code)

    print(errors.__str__())
    for err in errors:
        print(err[])
