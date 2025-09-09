@register_passable("trivial")
struct PlanMode[v: __mlir_type[`!kgen.string`] = __type_of("Invalid").value](
    EqualityComparable, Writable
):
    alias Invalid = PlanMode[]()

    alias LeftRecursive = PlanMode[__type_of("LeftRecursive").value]()
    alias LL = PlanMode[__type_of("LL").value]()
    alias PositivePeek = PlanMode[__type_of("PositivePeek").value]()

    alias value = StringLiteral[v]()

    fn __init__(out self):
        pass

    fn __eq__(self, other: Self) -> Bool:
        return True

    fn __eq__(self, other: PlanMode) -> Bool:
        return False

    fn write_to(self, mut w: Some[Writer]):
        w.write("PlanMode(", Self.value, ")")
