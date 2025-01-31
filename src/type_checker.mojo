from python import PythonObject, Python as py
from collections import Dict


struct TypeChecker:
    var visitor: NodeVisitor

    fn __init__(out self) raises:
        self.visitor = NodeVisitor()

    fn run(self, code: String) raises -> List[String]:
        function_signatures = py.evaluate("{}")
        errors = py.evaluate("[]")
        tree = parse_code(code)
        self.visitor.traverse_ast(tree, function_signatures, errors)
        var errs = List[String]()
        for err in errors:
            errs.append(String(err))
        return errs


fn parse_code(code: String) raises -> PythonObject:
    ast = py.import_module("ast")
    return ast.parse(code)


struct NodeVisitor:
    var _ast: PythonObject

    def __init__(out self):
        self._ast = py.import_module("ast")

    def isinstance(self, v: PythonObject, type: PythonObject) -> Bool:
        return py.is_type(v, type)

    def get_annotation(self, annotation: PythonObject) -> PythonObject:
        if self.isinstance(annotation, self._ast.Name):
            return annotation.id
        # Handle more complex type annotations if needed
        return None

    def get_expression_type(self, expr: PythonObject) -> PythonObject:
        if self.isinstance(expr, self._ast.Constant):
            return py.type(expr.value).__name__
        elif self.isinstance(expr, self._ast.Name):
            return "unknown"  # This requires more context (e.g., symbol table)
        # Add more expressions as needed
        return "unknown"

    def check_function_def(
        self, node: PythonObject, function_signatures: PythonObject
    ):
        # arg_types = [get_annotation(arg.annotation) for arg in node.args.args]
        arg_types = py.evaluate("[]")
        for arg in node.args.args:
            arg.append(self.get_annotation(arg.annotation))
        return_type = self.get_annotation(node.returns)

        # function_signatures[node.name] = {
        #     "arg_types": arg_types,
        #     "return_type": return_type,
        # }
        dct = py.evaluate("{}")
        dct["arg_types"] = arg_types
        dct["return_type"] = return_type

        function_signatures[node.name] = dct

    def check_call(
        self,
        node: PythonObject,
        function_signatures: PythonObject,
        errors: PythonObject,
    ):
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
                            func_name.__str__()
                        )
                        + " {}, got {}".format(
                            expected_type.__str__(), actual_type.__str__()
                        )
                    )

    def traverse_ast(
        self,
        node: PythonObject,
        function_signatures: PythonObject,
        errors: PythonObject,
    ):
        if self.isinstance(node, self._ast.FunctionDef):
            self.check_function_def(node, function_signatures)
        elif self.isinstance(node, self._ast.Call):
            self.check_call(node, function_signatures, errors)

        for child in self._ast.iter_child_nodes(node):
            self.traverse_ast(child, function_signatures, errors)
