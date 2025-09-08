# from collections import Set
import sys

# alias NODE_START: Scalar[DType.uint16] = 1 << 15
# alias ERROR_RECOVERY_BIT: Scalar[DType.uint16] = 1 << 14

# alias SquashedTransitions = Dict[InternalSquashedType, Plan]
# alias Automatons = Dict[InternalNonterminalType, RuleAutomaton]
# alias InternalStrToToken = Dict[StaticString, InternalTerminalType]
# alias InternalStrToNode = Dict[StaticString, InternalNonterminalType]
# alias RuleMap = FashHashMap[InternalNonterminalType, (StaticString, Rule)]
# alias SoftKeywords = Dict[InternalTerminalType, Set[StaticString]]
# alias FirstPlans = Dict[InternalNonterminalType, FirstPlan]


struct RuleType[v: __mlir_type[`!pop.int_literal`] = __type_of(-1).value](
    Identifiable
):
    alias Invalid = RuleType[]

    alias Identifier = RuleType[__type_of(1).value]
    alias Keyword = RuleType[__type_of(2).value]
    alias Or = RuleType[__type_of(3).value]
    alias Cut = RuleType[__type_of(4).value]
    alias Maybe = RuleType[__type_of(5).value]
    alias Multiple = RuleType[__type_of(6).value]
    alias NegativeLookahead = RuleType[__type_of(7).value]
    alias PositiveLookahead = RuleType[__type_of(8).value]
    alias Next = RuleType[__type_of(9).value]
    alias NodeMayBeOmmited = RuleType[__type_of(10).value]
    alias DoesErrorRecovery = RuleType[__type_of(11).value]

    var rules: (StaticString, StaticString)

    fn __init__(
        out self, value_1: StaticString = "", value_2: StaticString = ""
    ):
        @parameter
        if IntLiteral[self.v]() == -1:
            print("Invalid initialization.")
            sys.exit(1)

        self.rules = (value_1, value_2)

    # Initializers

    fn build(var self: Self.Identifier, value: StaticString) -> Self.Identifier:
        return {value}

    fn build(var self: Self.Keyword, value: StaticString) -> Self.Keyword:
        return {value}

    fn build(
        var self: Self.Or, value_1: StaticString, value_2: StaticString
    ) -> Self.Or:
        return {value_1, value_2}

    fn build(
        var self: Self.Cut, value_1: StaticString, value_2: StaticString
    ) -> Self.Cut:
        return {value_1, value_2}

    fn build(var self: Self.Maybe, value: StaticString) -> Self.Maybe:
        return {value}

    fn build(var self: Self.Multiple, value: StaticString) -> Self.Multiple:
        return {value}

    fn build(
        var self: Self.NegativeLookahead, value: StaticString
    ) -> Self.NegativeLookahead:
        return {value}

    fn build(
        var self: Self.PositiveLookahead, value: StaticString
    ) -> Self.PositiveLookahead:
        return {value}

    fn build(
        var self: Self.Next, value_1: StaticString, value_2: StaticString
    ) -> Self.Next:
        return {value_1, value_2}

    fn build(
        var self: Self.NodeMayBeOmmited, value: StaticString
    ) -> Self.NodeMayBeOmmited:
        return {value}

    fn build(
        var self: Self.DoesErrorRecovery, value: StaticString
    ) -> Self.DoesErrorRecovery:
        return {value}

    # Identifier
    fn __is__(self, other: Self) -> Bool:
        return True

    fn __is__(self, other: RuleType) -> Bool:
        return False

    # # Initializers
    # fn (
    #     out self: Self.Identifier,
    #     value: StaticString,
    #     v: IntLiteral[Self.Identifier.v] = {},
    # ):
    #     self.rules = (value, "")

    # fn __init__(
    #     out self: Self.Keyword,
    #     value: StaticString,
    #     v: IntLiteral[Self.Keyword.v] = {},
    # ):
    #     self.rules = (value, "")

    # fn __init__(
    #     var self: Self.Or,
    #     out o: Self.Or,
    #     value_1: StaticString,
    #     value_2: StaticString,
    # ):
    #     self.rules = (value_1, value_2)

    # fn __init__(
    #     var self: Self.Cut,
    #     out o: Self.Cut,
    #     value_1: StaticString,
    #     value_2: StaticString,
    # ):
    #     self.rules = (value_1, value_2)

    # fn __init__(
    #     out self: Self.Maybe,
    #     value: StaticString,
    #     v: IntLiteral[Self.Maybe.v] = {},
    # ):
    #     self.rules = (value, "")

    # fn __init__(
    #     out self: Self.Multiple,
    #     value: StaticString,
    #     v: IntLiteral[Self.Multiple.v] = {},
    # ):
    #     self.rules = (value, "")

    # fn __init__(
    #     out self: Self.NegativeLookahead,
    #     value: StaticString,
    #     v: IntLiteral[Self.NegativeLookahead.v] = {},
    # ):
    #     self.rules = (value, "")

    # fn __init__(
    #     out self: Self.PositiveLookahead,
    #     value: StaticString,
    #     v: IntLiteral[Self.PositiveLookahead.v] = {},
    # ):
    #     self.rules = (value, "")

    # fn __init__(
    #     var self: Self.Next,
    #     out
    #     value_1: StaticString,
    #     value_2: StaticString,
    #     v: IntLiteral[Self.Next.v] = {},
    # ):
    #     self.rules = (value_1, value_2)

    # fn __init__(
    #     out self: Self.NodeMayBeOmmited,
    #     value: StaticString,
    #     v: IntLiteral[Self.NodeMayBeOmmited.v] = {},
    # ):
    #     self.rules = (value, "")

    # fn __init__(
    #     out self: Self.DoesErrorRecovery,
    #     value: StaticString,
    #     v: IntLiteral[Self.DoesErrorRecovery.v] = {},
    # ):
    #     self.rules = (value, "")

    # Get value

    fn __getitem__(self: Self.Identifier) -> ref [self.rules[0]] StaticString:
        return self.rules[0]

    fn __getitem__(self: Self.Keyword) -> ref [self.rules[0]] StaticString:
        return self.rules[0]

    fn __getitem__(
        self: Self.Or,
    ) -> ref [self.rules] (StaticString, StaticString):
        if self.rules[0] == "":
            print("Invalid status")
            sys.exit(1)
        return self.rules

    fn __getitem__(
        self: Self.Cut,
    ) -> ref [self.rules] (StaticString, StaticString):
        if self.rules[0] == "":
            print("Invalid status")
            sys.exit(1)
        return self.rules

    fn __getitem__(self: Self.Maybe) -> ref [self.rules[0]] StaticString:
        return self.rules[0]

    fn __getitem__(self: Self.Multiple) -> ref [self.rules[0]] StaticString:
        return self.rules[0]

    fn __getitem__(
        self: Self.NegativeLookahead,
    ) -> ref [self.rules[0]] StaticString:
        return self.rules[0]

    fn __getitem__(
        self: Self.PositiveLookahead,
    ) -> ref [self.rules[0]] StaticString:
        return self.rules[0]

    fn __getitem__(
        self: Self.Next,
    ) -> ref [self.rules] (StaticString, StaticString):
        if self.rules[0] == "":
            print("Invalid status")
            sys.exit(1)
        return self.rules

    fn __getitem__(
        self: Self.NodeMayBeOmmited,
    ) -> ref [self.rules[0]] StaticString:
        return self.rules[0]

    fn __getitem__(
        self: Self.DoesErrorRecovery,
    ) -> ref [self.rules[0]] StaticString:
        return self.rules[0]

    # All the rest
    # fn __getitem__(self) -> ref [self.rules[0]] StaticString:
    #     if self.rules[0] == "":
    #         print("Invalid status")
    #         sys.exit(1)
    #     return self.rules[0]


fn run():
    rt = RuleType.Identifier().build("something")
    ref value = rt[]
    rte = RuleType.Cut().build("something", "something_else")
    ref value_2 = rte[]
