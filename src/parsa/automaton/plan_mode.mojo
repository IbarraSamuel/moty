@register_passable("trivial")
struct PlanMode(Writable):
    alias Invalid = -1

    alias LeftRecursive = 0
    alias LL = 1
    alias PositivePeek = 2

    var _v: Int

    @implicit
    fn __init__(out self, v: Int = Self.Invalid):
        self._v = v

    fn matches(self, other: Int) -> Bool:
        return self._v == other

    fn write_to(self, mut w: Some[Writer]):
        w.write("PlanMode(", self._v, ")")
