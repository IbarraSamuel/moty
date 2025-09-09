from parsa.automaton import SquashedTransitions


struct FirstPlan[v: __mlir_type[`!kgen.string`] = __type_of("Invalid").value](
    EqualityComparable
):
    alias InvalidType = FirstPlan[]
    alias CalculatedType = FirstPlan[__type_of("Calculated").value]
    alias CalculatingType = FirstPlan[__type_of("Calculating").value]

    alias Invalid = Self.InvalidType()
    alias Calculated = Self.CalculatedType()
    alias Calculating = Self.CalculatingType()

    alias value = StringLiteral[v]()

    var inner: Tuple[SquashedTransitions, Bool]

    fn __init__(out self, var v1: SquashedTransitions = {}, var v2: Bool = {}):
        self.inner = (v1^, v2)

    fn build(
        self: Self.CalculatedType, var v1: SquashedTransitions, var v2: Bool
    ) -> Self.CalculatedType:
        return {v1^, v2}

    fn build(self: Self.CalculatingType) -> Self.CalculatingType:
        return {}

    fn __getitem__(
        self: Self.CalculatedType,
    ) -> ref [self.inner] (SquashedTransitions, Bool):
        return self.inner

    fn __eq__(self, other: Self) -> Bool:
        return True

    fn __eq__(self, other: FirstPlan) -> Bool:
        return False
