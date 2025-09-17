@register_passable("trivial")
struct PlanMode(Identifiable, Writable):
    alias Invalid = PlanMode()

    alias LeftRecursive = PlanMode(0)
    alias LL = PlanMode(1)
    alias PositivePeek = PlanMode(2)

    var _v: Int

    fn __init__(out self, v: Int = -1):
        self._v = v

    fn __is__(self, other: Self) -> Bool:
        return self._v == other._v

    fn write_to(self, mut w: Some[Writer]):
        w.write("PlanMode(", self._v, ")")
