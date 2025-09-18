from os import abort
from sys.intrinsics import _type_is_eq


struct TransitionType(
    EqualityComparable,
    Hashable,
    Identifiable,
    ImplicitlyCopyable,
    ImplicitlyCopyable,
    Movable,
):
    alias Invalid = Self()

    alias Terminal = Self(0)
    alias Nonterminal = Self(1)
    alias Keyword = Self(2)
    alias PositiveLookaheadStart = Self(3)
    alias NegativeLookaheadStart = Self(4)
    alias LookaheadEnd = Self(5)

    var _v: Int
    var inner: (InternalTerminalType, InternalNonterminalType, StaticString)

    fn __init__(out self, v: Int = -1):
        self._v = v
        self.inner = ({}, {}, {})

    fn __is__(self, other: Self) -> Bool:
        return self._v == other._v

    fn __eq__(self, other: Self) -> Bool:
        return (
            self._v == other._v
            and self.inner[0] == other.inner[0]
            and self.inner[1] == other.inner[1]
            and self.inner[2] == other.inner[2]
        )

    fn __hash__(self, mut h: Some[Hasher]):
        h.update(self._v)
        h.update(self.inner[0])
        h.update(self.inner[1])
        h.update(self.inner[2])

    # Builders
    fn __call__(
        var self,
        *,
        var terminal: InternalTerminalType = {},
        var nonterminal: InternalNonterminalType = {},
        var string: StaticString = {},
    ) -> Self:
        if not (
            (
                self is materialize[Self.Terminal]()
                and terminal != {}
                and string != {}
            )
            or (self is materialize[Self.Nonterminal]() and nonterminal != {})
            or (self is materialize[Self.Keyword]() and string != {})
            or (self is materialize[Self.PositiveLookaheadStart]())
            or (self is materialize[Self.NegativeLookaheadStart]())
            or (self is materialize[Self.LookaheadEnd]())
        ):
            abort("Invalid transition type initialization.")

        new_self = Self(self._v)
        new_self.inner = (terminal, nonterminal, string)
        return new_self^

    # Getters
    fn get[t: Copyable](self) -> t:
        if (
            self is materialize[Self.Terminal]()
            and _type_is_eq[t, (InternalTerminalType, StaticString)]()
        ):
            return rebind[t]((self.inner[0], self.inner[2])).copy()
        elif (
            self is materialize[Self.Nonterminal]()
            and _type_is_eq[t, InternalNonterminalType]()
        ):
            return rebind[t](self.inner[1]).copy()
        elif (
            self is materialize[Self.Keyword]()
            and _type_is_eq[t, StaticString]()
        ):
            return rebind[t](self.inner[2]).copy()

        abort("Transition Type doesn't have values to get.")
        # NOTE: This never runs
        return rebind[t](self.inner).copy()
