alias lit[l: IntLiteral] = __type_of(l).value


@fieldwise_init
@register_passable("trivial")
struct TransitionTypeVariant[_v: __mlir_type[`!pop.int_literal`] = lit[-1]](
    EqualityComparable
):
    alias Invalid = TransitionTypeVariant[]()

    alias Terminal = TransitionTypeVariant[lit[0]]()
    alias Nonterminal = TransitionTypeVariant[lit[1]]()
    alias Keyword = TransitionTypeVariant[lit[2]]()
    alias PositiveLookaheadStart = TransitionTypeVariant[lit[3]]()
    alias NegativeLookaheadStart = TransitionTypeVariant[lit[4]]()
    alias LookaheadEnd = TransitionTypeVariant[lit[5]]()

    alias value = IntLiteral[_v]()

    @always_inline("builtin")
    fn __eq__(self, other: Self) -> Bool:
        return True

    @always_inline("builtin")
    fn __eq__(self, other: TransitionTypeVariant) -> Bool:
        return self.value == other.value

    fn matches(self, other: TransitionType) -> Bool:
        return self.value == other.variant

    fn new(
        var self: __type_of(Self.Terminal),
        terminal: InternalTerminalType,
        string: StaticString,
    ) -> TransitionType:
        return {self.value, {terminal, {}, string}}

    fn new(
        var self: __type_of(Self.Nonterminal),
        nonterminal: InternalNonterminalType,
    ) -> TransitionType:
        return {self.value, {{}, nonterminal, {}}}

    fn new(
        var self: __type_of(Self.Keyword), string: StaticString
    ) -> TransitionType:
        return {self.value, {{}, {}, string}}

    fn new(var self: __type_of(Self.PositiveLookaheadStart)) -> TransitionType:
        return {self.value, {{}, {}, {}}}

    fn new(var self: __type_of(Self.NegativeLookaheadStart)) -> TransitionType:
        return {self.value, {{}, {}, {}}}

    fn new(var self: __type_of(Self.LookaheadEnd)) -> TransitionType:
        return {self.value, {{}, {}, {}}}

    fn __getitem__(
        var self: __type_of(Self.Terminal), transition_type: TransitionType
    ) -> (InternalTerminalType, StaticString):
        return (transition_type.inner[0], transition_type.inner[2])

    fn __getitem__(
        var self: __type_of(Self.Nonterminal), transition_type: TransitionType
    ) -> InternalNonterminalType:
        return transition_type.inner[1]

    fn __getitem__(
        var self: __type_of(Self.Keyword), transition_type: TransitionType
    ) -> StaticString:
        return transition_type.inner[2]


@fieldwise_init
struct TransitionType(
    EqualityComparable, Hashable, ImplicitlyCopyable, Movable
):
    var variant: Int
    var inner: (InternalTerminalType, InternalNonterminalType, StaticString)

    fn __eq__(self, other: Self) -> Bool:
        return (
            self.variant == other.variant
            and self.inner[0] == other.inner[0]
            and self.inner[1] == other.inner[1]
            and self.inner[2] == other.inner[2]
        )

    fn __hash__(self, mut h: Some[Hasher]):
        h.update(self.variant)
        h.update(self.inner[0])
        h.update(self.inner[1])
        h.update(self.inner[2])
