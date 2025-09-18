from os import abort
from sys.intrinsics import _type_is_eq


@fieldwise_init
@register_passable("trivial")
struct TransitionTypeVariant(EqualityComparable):
    alias Invalid = -1

    alias Terminal = Self(0)
    alias Nonterminal = Self(1)
    alias Keyword = Self(2)
    alias PositiveLookaheadStart = Self(3)
    alias NegativeLookaheadStart = Self(4)
    alias LookaheadEnd = Self(5)

    var _v: Int

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        return self._v == other._v

    @always_inline("nodebug")
    fn __call__(
        var self,
        *,
        var terminal: InternalTerminalType = {},
        var nonterminal: InternalNonterminalType = {},
        var string: StaticString = {},
    ) -> TransitionType:
        if not (
            (self == Self.Terminal and terminal != {} and string != {})
            or (self == Self.Nonterminal and nonterminal != {})
            or (self == Self.Keyword and string != {})
            or (self == Self.PositiveLookaheadStart)
            or (self == Self.NegativeLookaheadStart)
            or (self == Self.LookaheadEnd)
        ):
            abort("Invalid transition type initialization.")

        return TransitionType(self, (terminal, nonterminal, string))


@fieldwise_init
struct TransitionType(
    EqualityComparable, Hashable, ImplicitlyCopyable, Movable
):
    var variant: TransitionTypeVariant
    var inner: (InternalTerminalType, InternalNonterminalType, StaticString)

    @always_inline("nodebug")
    fn matches(self, other: TransitionTypeVariant) -> Bool:
        return self.variant == other

    fn __eq__(self, other: Self) -> Bool:
        return (
            self.variant._v == other.variant._v
            and self.inner[0] == other.inner[0]
            and self.inner[1] == other.inner[1]
            and self.inner[2] == other.inner[2]
        )

    fn __hash__(self, mut h: Some[Hasher]):
        h.update(self.variant._v)
        h.update(self.inner[0])
        h.update(self.inner[1])
        h.update(self.inner[2])

    # Getters
    fn get[t: Copyable](self) -> t:
        if (
            self.matches(TransitionTypeVariant.Terminal)
            and _type_is_eq[t, (InternalTerminalType, StaticString)]()
        ):
            return rebind[t]((self.inner[0], self.inner[2])).copy()
        elif (
            self.matches(TransitionTypeVariant.Nonterminal)
            and _type_is_eq[t, InternalNonterminalType]()
        ):
            return rebind[t](self.inner[1]).copy()
        elif (
            self.matches(TransitionTypeVariant.Keyword)
            and _type_is_eq[t, StaticString]()
        ):
            return rebind[t](self.inner[2]).copy()

        abort("Transition Type doesn't have values to get.")
        # NOTE: This never runs
        return rebind[t](self.inner).copy()
