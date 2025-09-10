from hashlib import Hasher
from collections import Set
from memory.owned_pointer import OwnedPointer
import sys

from parsa.automaton.transition_type import TransitionType
from parsa.automaton.rule import Rule
from parsa.automaton.plan_mode import PlanMode
from parsa.automaton.first_plan import FirstPlan

alias NODE_START: Scalar[DType.uint16] = 1 << 15
alias ERROR_RECOVERY_BIT: Scalar[DType.uint16] = 1 << 14

alias SquashedTransitions = Dict[InternalSquashedType, Plan]
alias InternalStrToToken = Dict[StaticString, InternalTerminalType]
alias InternalStrToNode = Dict[StaticString, InternalNonterminalType]


@fieldwise_init
struct InternalSquashedType(Copyable, EqualityComparable, Hashable, Movable):
    var inner: Scalar[DType.uint16]

    @always_inline
    fn is_leaf(self) -> Bool:
        return self.inner < NODE_START

    @always_inline
    fn is_error_recovery(self) -> Bool:
        return (self.inner & ERROR_RECOVERY_BIT) > 0

    @always_inline
    fn remove_error_recovery_bit(self) -> Self:
        return Self(self.inner & ~ERROR_RECOVERY_BIT)

    @always_inline
    fn set_error_recovery_bit(self) -> Self:
        return Self(self.inner | ERROR_RECOVERY_BIT)

    fn __eq__(self, other: Self) -> Bool:
        return self.inner == other.inner

    fn __hash__(self, mut h: Some[Hasher]):
        h.update(self.inner)


trait Squashable:
    fn to_squashed(self) -> InternalSquashedType:
        ...


@fieldwise_init
struct InternalNonterminalType(Copyable, Movable, Squashable):
    var inner: Scalar[DType.uint16]

    fn __init__(out self):
        self.inner = 0

    fn to_squashed(self) -> InternalSquashedType:
        return {self.inner}


@fieldwise_init
struct InternalTerminalType(Copyable, Movable, Squashable):
    var inner: UInt16

    fn __init__(out self):
        self.inner = 0

    fn to_squashed(self) -> InternalSquashedType:
        return {self.inner}


@fieldwise_init
@register_passable("trivial")
struct NFAStateId(Copyable, EqualityComparable, Hashable, Movable):
    var inner: UInt

    fn __hash__(self, mut h: Some[Hasher]):
        h.update(self.inner)

    fn __eq__(self, other: Self) -> Bool:
        return self.inner == other.inner


@fieldwise_init
@register_passable("trivial")
struct DFAStateId:
    var inner: UInt


struct NFAState(Copyable, Movable):
    var transitions: List[NFATransition]


@fieldwise_init
struct DFAState(Copyable, Movable):
    var transitions: List[DFATransition]
    var nfa_set: Set[NFAStateId]
    var is_final: Bool
    var is_calculated: Bool
    var node_may_be_omitted: Bool
    var list_index: DFAStateId
    var from_alternative_list_index: Optional[DFAStateId]

    var transition_to_plan: FastLookupTransitions
    var from_rule: StaticString


struct NFATransition(Copyable, Movable):
    var type_: Optional[TransitionType]
    var to: NFAStateId


struct DFATransition[origin: MutableOrigin = MutableAnyOrigin](
    Copyable, Movable
):
    var type_: TransitionType
    var to: Pointer[DFAState, origin]


struct StackMode[
    v: __mlir_type[`!kgen.string`] = __type_of("Invalid").value,
](Writable, Copyable, Movable):
    alias InvalidType = StackMode[]
    alias AlternativeType = StackMode[v = __type_of("Alternative").value]
    alias LLType = StackMode[v = __type_of("LL").value]

    alias Alternative = Self.AlternativeType()
    alias LL = Self.LLType()

    var inner: Optional[fn () -> Plan]

    fn __init__(out self):
        self.inner = None

    fn __init__(out self, v1: fn () -> Plan):
        self.inner = None

    fn build(
        self: Self.AlternativeType, v: fn () -> Plan
    ) -> Self.AlternativeType:
        return {v}

    fn build(self: Self.LLType) -> ref [self] Self.LLType:
        return self

    fn __getitem__(self: Self.AlternativeType) -> fn () -> Plan:
        return self.inner.value()

    fn write_to(self, mut w: Some[Writer]):
        @parameter
        if StringLiteral[v]() == "Alternative":
            ref dfa = self.inner.value()().next_dfa()
            w.write(
                "Alternative(",
                dfa.from_rule,
                " #",
                dfa.list_index.inner,
                ")",
            )
        else:
            w.write("LL")


struct Push(Copyable, Movable, Representable, Writable):
    var node_type: InternalNonterminalType
    var next_dfa: fn () -> DFAState
    var stack_mode: StackMode

    fn write_to(self, mut w: Some[Writer]):
        var dfa = self.next_dfa()
        w.write(
            "Push(",
            "node_type:",
            self.node_type.inner,
            ", next_dfa:",
            dfa.from_rule,
            " #",
            dfa.list_index.inner,
            ", stack_mode:",
            self.stack_mode,
            ")",
        )

    fn __repr__(self) -> String:
        return String(self)


struct Plan(Copyable, Movable, Writable):
    var pushes: List[Push]
    var next_dfa: fn () -> DFAState
    var type_: InternalSquashedType
    var mode: PlanMode
    var debug_text: StaticString

    fn write_to(self, mut w: Some[Writer]):
        var _dfa = self.next_dfa()
        # w.write("Push(pushes:")
        self.pushes.write_to(w)
        w.write(
            # ", next_dfa:",
            # dfa.from_rule,
            # " #",
            # dfa.list_index.inner,
            ", type_:",
            self.type_.inner,
            ", mode:",
            self.mode,
            ", debug_text:",
            self.debug_text,
            ")",
        )


struct Keywords:
    var counter: UInt
    var keywords: Dict[StaticString, InternalSquashedType]

    fn __init__(out self):
        self.counter = 0
        self.keywords = {}

    fn add(mut self, keyword: StaticString):
        if keyword not in self.keywords:
            self.keywords[keyword] = Self.keyword_to_squashed(self.counter)
            self.counter += 1

    @staticmethod
    fn keyword_to_squashed(number: UInt) -> InternalSquashedType:
        return InternalSquashedType(number)

    fn squashed(self, keyword: StaticString) -> Optional[InternalSquashedType]:
        return self.keywords.get(keyword)


struct RuleAutomaton:
    var type_: InternalNonterminalType
    var nfa_states: List[NFAState]
    var dfa_states: List[UnsafePointer[DFAState]]  # sould be a Box...
    var name: StaticString
    var node_may_be_ommited: Bool
    var nfa_end_id: NFAStateId
    var no_transition_dfa_id: Optional[DFAStateId]
    var fallback_plans: List[UnsafePointer[Plan]]  # Should be a Box...
    var does_error_recovery: Bool

    fn build(
        mut self,
        nonterminal_map: InternalStrToNode,
        terminal_map: InternalStrToToken,
        mut keywords: Keywords,
        rule: Rule,
    ) -> (NFAStateId, NFAStateId):
        @parameter
        fn _build(mut automaton: Self, rule: Rule) -> (NFAStateId, NFAStateId):
            return automaton.build(
                nonterminal_map, terminal_map, keywords, rule
            )

        if rule is Rule.Identifier:
            var string = rebind[Rule.IdentifierType](rule)[]
            var start, end = self.new_nfa_states()
            var t = terminal_map.get(string)
            if t:
                self.add_transition(
                    start, end, TransitionType.Terminal.build(t.value(), string)
                )
            elif nonterminal_map.get(string):
                var nt = nonterminal_map.get(string)
                self.add_transition(
                    start, end, TransitionType.Nonterminal.build(nt.value())
                )
            else:
                print(
                    "No terminal / nonterminal found for",
                    string,
                    "; token map =",
                    terminal_map,
                    "; node map =",
                    nonterminal_map,
                )
                sys.exit(1)

            return (start, end)

        elif rule is Rule.Keyword:
            var string = rebind[Rule.KeywordType](rule)[]
            var start, end = self.new_nfa_states()
            self.add_transition(
                start, end, TransitionType.Keyword.build(string)
            )
            keywords.add(string)
            return (start, end)

        elif rule is Rule.Or:
            var rule1, rule2 = rebind[Rule.OrType](rule)[]
            var start, end = self.new_nfa_states()
            for r in [rule1, rule2]:
                var x, y = _build(self, r)
                self.add_empty_transition(start, x)
                self.add_empty_transition(y, end)
            return (start, end)

        elif rule is Rule.Maybe:
            var rule1 = rebind[Rule.MaybeType](rule)[]
            var start, end = _build(self, rule1)
            self.add_empty_transition(start, end)
            return (start, end)

        elif rule is Rule.Multiple:
            var rule1 = rebind[Rule.MultipleType](rule)[]
            var start, end = _build(self, rule1)
            self.add_empty_transition(end, start)
            return (start, end)

        elif rule is Rule.NegativeLookahead:
            var rule1 = rebind[Rule.NegativeLookaheadType](rule)[]
            var start, end = _build(self, rule1)
            var new_start, new_end = self.new_nfa_states()
            self.add_transition(
                new_start, start, TransitionType.NegativeLookaheadStart
            )
            self.add_transition(end, new_end, TransitionType.LookaheadEnd)
            return (new_start, new_end)

        elif rule is Rule.PositiveLookahead:
            var rule1 = rebind[Rule.PositiveLookaheadType](rule)[]
            var start, end = _build(self, rule1)
            var new_start, new_end = self.new_nfa_states()
            self.add_transition(
                new_start, start, TransitionType.PositiveLookaheadStart
            )
            self.add_transition(end, new_end, TransitionType.LookaheadEnd)
            return (new_start, new_end)

        # TODO: Unimplemented
        elif rule is Rule.Cut:
            print("TODO: UNIMPLEMENTED")
            sys.exit(1)

        elif rule is Rule.Next:
            var rule1, rule2 = rebind[Rule.NextType](rule)[]
            var start1, end1 = _build(self, rule1)
            var start2, end2 = _build(self, rule2)
            # What is it doing here?
            self.add_empty_transition(end1, start2)
            return (start1, end2)

        elif rule is Rule.NodeMayBeOmmited:
            var _rule = rebind[Rule.NodeMayBeOmmitedType](rule)[]
            self.node_may_be_ommited = True
            return _build(self, _rule)
        elif rule is Rule.DoesErrorRecovery:
            var _rule = rebind[Rule.DoesErrorRecoveryType](rule)[]
            self.does_error_recovery = True
            return _build(self, _rule)

        print("Invalid Rule:", rule)
        sys.exit(1)

    fn nfa_state_mut(
        mut self, id: NFAStateId
    ) -> ref [self.nfa_states] NFAState:
        return self.nfa_states[id.inner]

    fn nfa_state(self, id: NFAStateId) -> ref [self.nfa_states] NFAState:
        return self.nfa_states[id.inner]

    fn new_nfa_states(mut self) -> (NFAStateId, NFAStateId):
        @parameter
        fn new() -> NFAStateId:
            var nfa_state = NFAState(transitions={})
            self.nfa_states.push(nfa_states)
            return NFAStateId(len(self.nfa_states) - 1)

        return new(), new()

    fn add_transition(
        mut self,
        start: NFAStateId,
        to: NFAStateId,
        type_: Optional[TransitionType],
    ):
        self.nfa_state_mut(start).transitions.push(NFATransition(type_, to))

    fn add_empty_transition(mut self, start: NFAStateId, to: NFAStateId):
        self.add_transition(start, to, None)

    fn group_nfas(self, nfa_state_ids: List[NFAStateId]) -> Set[NFAStateId]:
        var set_ = {v for v in nfa_state_ids}
        for nfa_state_id in nfa_state_ids:
            for transition in self.nfa_state(nfa_state_id).transitions:
                if not transition.type_:
                    set_.insert(transition.to)
                    if transition.to not in nfa_state_ids:
                        lst = [v for v in set_]
                        set_.extend(self.group_nfas(lst^))

        return set_

    # TODO: MISSING
    # nfa_to_dfa
    # construct_powerset
    # construct_powerset_for_dfa
    # add_no_transition_dfa_if_neccessary
    # illustrate_dfa


# TODO: Should implement iterator but I will iterate the inner list and ignore None values. That's all.
struct FastLookupTransitions(Copyable, Movable):
    var inner: List[Optional[Plan]]

    fn __init__(out self):
        self.inner = {}

    fn __init__(out self, var value: List[Optional[Plan]]):
        self.inner = value^

    @staticmethod
    fn new_empty() -> Self:
        self = Self()

    @staticmethod
    fn from_plans(
        terminal_count: UInt, transitions: SquashedTransitions
    ) -> Self:
        if terminal_count == 0:
            print("Invalid state for terminal count:", terminal_count)
            sys.exit(1)

        var lst: List[Optional[Plan]] = [None for _ in range(terminal_count)]
        return Self(lst^)

    fn extend(mut self, other: SquashedTransitions):
        for it in other.items():
            ref index = it.key
            ref plan = it.value
            self.inner[index.inner] = plan.copy()

    fn lookup(
        self, index: InternalSquashedType
    ) -> ref [self.inner] Optional[Plan]:
        return self.inner[index.inner]
