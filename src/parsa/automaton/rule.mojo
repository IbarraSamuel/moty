# from collections import Set
import sys


# alias SquashedTransitions = Dict[InternalSquashedType, Plan]
# alias Automatons = Dict[InternalNonterminalType, RuleAutomaton]
# alias InternalStrToToken = Dict[StaticString, InternalTerminalType]
# alias InternalStrToNode = Dict[StaticString, InternalNonterminalType]
# alias RuleMap = FashHashMap[InternalNonterminalType, (StaticString, Rule)]
# alias SoftKeywords = Dict[InternalTerminalType, Set[StaticString]]
# alias FirstPlans = Dict[InternalNonterminalType, FirstPlan]


struct Rule[v: __mlir_type[`!kgen.string`] = __type_of("Invalid").value](
    Identifiable
):
    alias InvalidType = Rule[]

    alias IdentifierType = Rule[__type_of("Identifier").value]
    alias KeywordType = Rule[__type_of("Keyword").value]
    alias OrType = Rule[__type_of("Or").value]
    alias CutType = Rule[__type_of("Cut").value]
    alias MaybeType = Rule[__type_of("Maybe").value]
    alias MultipleType = Rule[__type_of("Multiple").value]
    alias NegativeLookaheadType = Rule[__type_of("NegativeLookahead").value]
    alias PositiveLookaheadType = Rule[__type_of("PositiveLookahead").value]
    alias NextType = Rule[__type_of("Next").value]
    alias NodeMayBeOmmitedType = Rule[__type_of("NodeMayBeOmmited").value]
    alias DoesErrorRecoveryType = Rule[__type_of("DoesErrorRecovery").value]

    alias Invalid = Self.InvalidType()

    alias Identifier = Self.IdentifierType()
    alias Keyword = Self.KeywordType()
    alias Or = Self.OrType()
    alias Cut = Self.CutType()
    alias Maybe = Self.MaybeType()
    alias Multiple = Self.MultipleType()
    alias NegativeLookahead = Self.NegativeLookaheadType()
    alias PositiveLookahead = Self.PositiveLookaheadType()
    alias Next = Self.NextType()
    alias NodeMayBeOmmited = Self.NodeMayBeOmmitedType()
    alias DoesErrorRecovery = Self.DoesErrorRecoveryType()

    var rules: (StaticString, StaticString)

    fn __init__(
        out self, var value_1: StaticString = "", var value_2: StaticString = ""
    ):
        self.rules = (value_1, value_2)

    # Initializers

    fn build(
        var self: Self.IdentifierType, value: StaticString
    ) -> Self.IdentifierType:
        return {value}

    fn build(
        var self: Self.KeywordType, value: StaticString
    ) -> Self.KeywordType:
        return {value}

    fn build(
        var self: Self.OrType, value_1: StaticString, value_2: StaticString
    ) -> Self.OrType:
        return {value_1, value_2}

    fn build(
        var self: Self.CutType, value_1: StaticString, value_2: StaticString
    ) -> Self.CutType:
        return {value_1, value_2}

    fn build(var self: Self.MaybeType, value: StaticString) -> Self.MaybeType:
        return {value}

    fn build(
        var self: Self.MultipleType, value: StaticString
    ) -> Self.MultipleType:
        return {value}

    fn build(
        var self: Self.NegativeLookaheadType, value: StaticString
    ) -> Self.NegativeLookaheadType:
        return {value}

    fn build(
        var self: Self.PositiveLookaheadType, value: StaticString
    ) -> Self.PositiveLookaheadType:
        return {value}

    fn build(
        var self: Self.NextType, value_1: StaticString, value_2: StaticString
    ) -> Self.NextType:
        return {value_1, value_2}

    fn build(
        var self: Self.NodeMayBeOmmitedType, value: StaticString
    ) -> Self.NodeMayBeOmmitedType:
        return {value}

    fn build(
        var self: Self.DoesErrorRecoveryType, value: StaticString
    ) -> Self.DoesErrorRecoveryType:
        return {value}

    # Identifier
    fn __is__(self, other: Self) -> Bool:
        return True

    fn __is__(self, other: Rule) -> Bool:
        return False

    # Getters
    fn __getitem__(
        self: Self.IdentifierType,
    ) -> ref [self.rules[0]] StaticString:
        return self.rules[0]

    fn __getitem__(self: Self.KeywordType) -> ref [self.rules[0]] StaticString:
        return self.rules[0]

    fn __getitem__(
        self: Self.OrType,
    ) -> ref [self.rules] (StaticString, StaticString):
        return self.rules

    fn __getitem__(
        self: Self.CutType,
    ) -> ref [self.rules] (StaticString, StaticString):
        return self.rules

    fn __getitem__(self: Self.MaybeType) -> ref [self.rules[0]] StaticString:
        return self.rules[0]

    fn __getitem__(self: Self.MultipleType) -> ref [self.rules[0]] StaticString:
        return self.rules[0]

    fn __getitem__(
        self: Self.NegativeLookaheadType,
    ) -> ref [self.rules[0]] StaticString:
        return self.rules[0]

    fn __getitem__(
        self: Self.PositiveLookaheadType,
    ) -> ref [self.rules[0]] StaticString:
        return self.rules[0]

    fn __getitem__(
        self: Self.NextType,
    ) -> ref [self.rules] (StaticString, StaticString):
        return self.rules

    fn __getitem__(
        self: Self.NodeMayBeOmmitedType,
    ) -> ref [self.rules[0]] StaticString:
        return self.rules[0]

    fn __getitem__(
        self: Self.DoesErrorRecoveryType,
    ) -> ref [self.rules[0]] StaticString:
        return self.rules[0]
