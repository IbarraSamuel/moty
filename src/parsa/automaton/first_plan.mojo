from parsa.automaton import SquashedTransitions
import sys


struct FirstPlan(Copyable, Identifiable, Movable):
    alias Invalid = Self()
    alias Calculated = Self(0)
    alias Calculating = Self(1)

    var _v: Int
    var inner: Tuple[SquashedTransitions, Bool]

    fn __init__(out self, v: Int = -1):
        self._v = v
        self.inner = ({}, {})

    fn __is__(self, other: Self) -> Bool:
        return self._v == other._v

    fn __call__(
        self,
        *,
        var plans: SquashedTransitions = {},
        var is_left_recursive: Bool = {},
    ) -> Self:
        new_self = Self(self._v)
        if (
            self is materialize[Self.Calculated]()
            and len(plans) == 0
            and is_left_recursive != {}
        ):
            new_self.inner = {plans^, is_left_recursive}
        elif self is materialize[Self.Calculating]():
            pass
        else:
            print("Failed to create first plan.")
            sys.exit(1)
        return new_self^

    fn get(self) -> ref [self.inner] (SquashedTransitions, Bool):
        if not (self is materialize[Self.Calculated]()):
            print("Invalid getter for FirstPlan.Calculated.")
            sys.exit(1)
        return self.inner
