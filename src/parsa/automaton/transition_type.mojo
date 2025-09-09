struct TransitionType[
    v: __mlir_type[`!kgen.string`] = __type_of("Invalid").value
](Movable, Copyable):
    alias InvalidType = TransitionType[]

    alias TerminalType = TransitionType[__type_of("Terminal").value]
    alias NonterminalType = TransitionType[__type_of("Nonterminal").value]
    alias KeywordType = TransitionType[__type_of("Keyword").value]
    alias PositiveLookaheadType = TransitionType[
        __type_of("PositiveLookahead").value
    ]
    alias NegativeLookaheadType = TransitionType[
        __type_of("NegativeLookahead").value
    ]
    alias LookaheadEndType = TransitionType[__type_of("LookaheadEnd").value]

    alias Terminal = Self.TerminalType()
    alias Nonterminal = Self.NonterminalType()
    alias Keyword = Self.KeywordType()
    alias PositiveLookahead = Self.PositiveLookaheadType()
    alias NegativeLookahead = Self.NegativeLookaheadType()
    alias LookaheadEnd = Self.LookaheadEndType()

    var inner: (InternalTerminalType, InternalNonterminalType, StaticString)

    fn __init__(
        out self,
        var value_1: InternalTerminalType = {},
        var value_2: InternalNonterminalType = {},
        var value_3: StaticString = {},
    ):
        self.inner = (value_1^, value_2^, value_3)

    # Builders
    fn build(
        self: Self.TerminalType,
        var value_1: InternalTerminalType,
        # value_2: InternalNonterminalType,
        var value_3: StaticString,
    ) -> Self.TerminalType:
        return {value_1^, {}, value_3}

    fn build(
        self: Self.NonterminalType,
        # value_1: InternalTerminalType,
        var value_2: InternalNonterminalType,
        # value_3: StaticString,
    ) -> Self.NonterminalType:
        return {{}, value_2^, {}}

    fn build(
        self: Self.KeywordType,
        # value_1: InternalTerminalType,
        # value_2: InternalNonterminalType,
        var value_3: StaticString,
    ) -> Self.KeywordType:
        return {{}, {}, value_3}

    fn build(
        self: Self.PositiveLookaheadType,
        # value_1: InternalTerminalType,
        # value_2: InternalNonterminalType,
        # value_3: StaticString,
    ) -> Self.PositiveLookaheadType:
        return {}

    fn build(
        self: Self.NegativeLookaheadType,
        # value_1: InternalTerminalType,
        # value_2: InternalNonterminalType,
        # value_3: StaticString,
    ) -> Self.NegativeLookaheadType:
        return {}

    fn build(
        self: Self.LookaheadEndType,
        # value_1: InternalTerminalType,
        # value_2: InternalNonterminalType,
        # value_3: StaticString,
    ) -> Self.LookaheadEndType:
        return {}

    # Getters
    fn __getitem__(
        self: Self.TerminalType,
    ) -> (
        InternalTerminalType,
        # InternalNonterminalType,
        StaticString,
    ):
        return (self.inner[0].copy(), self.inner[2])

    fn __getitem__(
        self: Self.NonterminalType,
    ) -> ref [self.inner] (
        # InternalTerminalType,
        InternalNonterminalType
        # StaticString,
    ):
        return self.inner[1]

    fn __getitem__(
        self: Self.KeywordType,
    ) -> ref [self.inner] (
        # InternalTerminalType,
        # InternalNonterminalType,
        StaticString
    ):
        return self.inner[2]

    # fn __getitem__(
    #     self: PositiveLookaheadType,
    # ) -> ref [self.inner] (
    #     # InternalTerminalType,
    #     # InternalNonterminalType,
    #     # StaticString,
    # ):
    #     return self.inner

    # fn __getitem__(
    #     self: NegativeLookaheadType,
    # ) -> ref [self.inner] (
    #     # InternalTerminalType,
    #     # InternalNonterminalType,
    #     # StaticString,
    # ):
    #     return self.inner

    # fn __getitem__(
    #     self: LookaheadEndType,
    # ) -> ref [self.inner] (
    #     # InternalTerminalType,
    #     # InternalNonterminalType,
    #     # StaticString,
    # ):
    #     return self.inner
