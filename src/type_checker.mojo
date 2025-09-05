from python import PythonObject, Python as py
from config import LogType, Config


struct TypeChecker:
    var visitor: NodeVisitor

    fn __init__(out self, config: Config) raises:
        self.visitor = NodeVisitor(config)

    fn run(self, code: String) raises -> List[String]:
        function_signatures = py.evaluate("{}")
        errors = py.evaluate("[]")
        tree = parse(code)
        self.visitor.traverse_ast(tree, function_signatures, errors)
        var errs = List[String]()
        for err in errors:
            errs.append(String(err))
        return errs


fn parse(code: String) raises -> PythonObject:
    ast = py.import_module("ast")
    return ast.parse(code)


struct NodeVisitor:
    var _ast: PythonObject
    var _isinstance: PythonObject
    var log_type: LogType
    # var _typeof: PythonObject

    fn __init__(out self, config: Config) raises:
        self._ast = py.import_module("ast")
        builtins = py.import_module("builtins")
        self._isinstance = builtins.isinstance
        self.log_type = config.log_type.copy()
        # self._typeof = builtins.type

    fn print(
        self,
        *args: String,
        input_level: String = "debug",
        log_type: LogType = LogType.silent,
    ):
        if log_type == LogType.silent:
            return

        if log_type == LogType.verbose:
            for arg in args:
                print(arg, end=" ")
                print()

            print()

    fn isinstance(self, v: PythonObject, type: PythonObject) raises -> Bool:
        return self._isinstance(v, type).__bool__()

    fn get_annotation(self, annotation: PythonObject) raises -> PythonObject:
        if self.isinstance(annotation, self._ast.Name):
            return annotation.id
        # Handle more complex type annotations if needed
        return None

    fn get_expression_type(self, expr: PythonObject) raises -> PythonObject:
        if self.isinstance(expr, self._ast.Constant):
            return py.type(expr.value).__name__
        elif self.isinstance(expr, self._ast.Name):
            return "unknown"  # This requires more context (e.g., symbol table)
        # Add more expressions as needed
        return "unknown"

    fn check_function_def(
        self, node: PythonObject, function_signatures: PythonObject
    ) raises:
        # arg_types = [get_annotation(arg.annotation) for arg in node.args.args]
        arg_types = py.evaluate("[]")
        self.print("Creating a list:", String(arg_types))
        for arg in node.args.args:
            arg_types.append(self.get_annotation(arg.annotation))
        return_type = self.get_annotation(node.returns)

        # function_signatures[node.name] = {
        #     "arg_types": arg_types,
        #     "return_type": return_type,
        # }
        dct = py.evaluate("{}")
        dct["arg_types"] = arg_types
        dct["return_type"] = return_type

        function_signatures[node.name] = dct

    fn check_call(
        self,
        node: PythonObject,
        function_signatures: PythonObject,
        errors: PythonObject,
    ) raises:
        func_name = node.func.id
        if func_name in function_signatures:
            func_sig = function_signatures[func_name]

            # Check argument types
            zip = py.import_module("builtins").zip
            for elem in zip(node.args, func_sig["arg_types"]):
                arg_value, expected_type = elem[0], elem[1]
                actual_type = self.get_expression_type(arg_value)
                if actual_type != expected_type:
                    errors.append(
                        "Type error in call to {}: Expected".format(
                            String(func_name)
                        )
                        + " {}, got {}".format(
                            String(expected_type), String(actual_type)
                        )
                    )

    fn traverse_ast(
        self,
        node: PythonObject,
        function_signatures: PythonObject,
        errors: PythonObject,
    ) raises:
        if self.isinstance(node, self._ast.FunctionDef):
            self.print("Checking function:", String(node))
            self.check_function_def(node, function_signatures)
        elif self.isinstance(node, self._ast.Call):
            self.print("Checking Call:", String(node))
            self.check_call(node, function_signatures, errors)

        for child in self._ast.iter_child_nodes(node):
            self.print("Checking child:", String(child))
            self.traverse_ast(child, function_signatures, errors)
