from hashlib import Hasher
from collections import Set
import sys

from parsa.automaton.transition_type import TransitionType
from parsa.automaton.rule import Rule
from parsa.automaton.plan_mode import PlanMode

alias NODE_START: UInt16 = 1 << 15
alias ERROR_RECOVERY_BIT: UInt16 = 1 << 14

alias SquashedTransitions[dfa_origins: ImmutableOrigin] = Dict[
    InternalSquashedType, Plan[dfa_origins]
]

alias Automatons[dfa_origin: ImmutableOrigin] = Dict[
    InternalNonterminalType, RuleAutomaton[dfa_origin]
]
alias InternalStrToToken = Dict[StaticString, InternalTerminalType]
alias InternalStrToNode = Dict[StaticString, InternalNonterminalType]
alias RuleMap = Dict[InternalNonterminalType, (StaticString, Rule)]
alias SoftKeywords = Dict[InternalTerminalType, Set[StaticString]]
alias FirstPlans[dfa_origin: ImmutableOrigin] = Dict[
    InternalNonterminalType, FirstPlan[dfa_origin]
]

alias string = __mlir_type[`!kgen.string`]

# TODO THINGS:
# 1. move out all these Materialize things.
# 3. Use abort instead of these sys.exit(1) things, because those will not expose the place where the issue happened.


@register_passable("trivial")
struct InternalSquashedType(EqualityComparable, Hashable):
    var inner: UInt16

    fn __init__(out self, inner: UInt16 = 0):
        self.inner = inner

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
@register_passable("trivial")
struct InternalNonterminalType(
    EqualityComparable, Hashable, Representable, Squashable, Writable
):
    var inner: UInt16

    fn __init__(out self):
        self.inner = 0

    fn write_to(self, mut w: Some[Writer]):
        w.write("InternalNonterminalType(", self.inner, ")")

    fn __repr__(self) -> String:
        return String(self)

    fn __eq__(self, other: Self) -> Bool:
        return self.inner == other.inner

    fn __hash__(self, mut h: Some[Hasher]):
        h.update(self.inner)

    fn to_squashed(self) -> InternalSquashedType:
        return {self.inner}


@fieldwise_init
@register_passable("trivial")
struct InternalTerminalType(
    EqualityComparable, Hashable, Representable, Squashable, Writable
):
    var inner: UInt16

    fn __init__(out self):
        self.inner = 0

    fn write_to(self, mut w: Some[Writer]):
        w.write("InternalTerminalType(", self.inner, ")")

    fn __repr__(self) -> String:
        return String(self)

    fn __eq__(self, other: Self) -> Bool:
        return self.inner == other.inner

    fn __hash__(self, mut h: Some[Hasher]):
        h.update(self.inner)

    fn to_squashed(self) -> InternalSquashedType:
        return {self.inner}


@register_passable("trivial")
struct NFAStateId(Copyable, EqualityComparable, Hashable, Movable):
    var inner: UInt

    fn __init__(out self, inner: UInt = 0):
        self.inner = inner

    fn __hash__(self, mut h: Some[Hasher]):
        h.update(self.inner)

    fn __eq__(self, other: Self) -> Bool:
        return self.inner == other.inner


@fieldwise_init
@register_passable("trivial")
struct DFAStateId(EqualityComparable, Hashable):
    var inner: UInt

    fn __hash__(self, mut h: Some[Hasher]):
        h.update(self.inner)

    fn __eq__(self, other: Self) -> Bool:
        return self.inner == other.inner


@fieldwise_init
struct NFAState(Copyable, Movable):
    var transitions: List[NFATransition]

    fn is_lookahead_end(self) -> Bool:
        for t in self.transitions:
            if (
                t.type_
                and t.type_.value()
                is materialize[TransitionType.LookaheadEnd]()
            ):
                return True
        return False


struct FirstPlan[dfa_origin: ImmutableOrigin](Copyable, Identifiable, Movable):
    alias Invalid = Self()
    alias Calculated = Self(0)
    alias Calculating = Self(1)

    var _v: Int
    var inner: Tuple[SquashedTransitions[dfa_origin], Bool]

    fn __init__(out self, v: Int = -1):
        self._v = v
        self.inner = ({}, {})

    fn __is__(self, other: Self) -> Bool:
        return self._v == other._v

    fn __call__(
        self,
        *,
        var plans: SquashedTransitions[dfa_origin] = {},
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

    fn get(self) -> ref [self.inner] (SquashedTransitions[dfa_origin], Bool):
        if not (self is materialize[Self.Calculated]()):
            print("Invalid getter for FirstPlan.Calculated.")
            sys.exit(1)
        return self.inner


@fieldwise_init
struct DFAState[dfa_origin: ImmutableOrigin](Copyable, Movable):
    var transitions: List[DFATransition[dfa_origin]]
    var nfa_set: Set[NFAStateId]
    var is_final: Bool
    var is_calculated: Bool
    var node_may_be_omitted: Bool
    var list_index: DFAStateId
    var from_alternative_list_index: Optional[DFAStateId]

    var transition_to_plan: FastLookupTransitions[dfa_origin]
    var from_rule: StaticString

    fn is_lookahead_end(self) -> Bool:
        for t in self.transitions:
            if t.type_ is materialize[TransitionType.LookaheadEnd]():
                return True

        return False

    fn nonterminal_transition_ids(self) -> List[InternalNonterminalType]:
        return [
            t.type_.get[InternalNonterminalType]()
            for t in self.transitions
            if t.type_ is materialize[TransitionType.Nonterminal]()
        ]


@fieldwise_init
struct NFATransition(Copyable, Movable):
    var type_: Optional[TransitionType]
    var to: NFAStateId

    fn is_terminal_nonterminal_or_keyword(self) -> Bool:
        return self.type_ and (
            self.type_.value() is materialize[TransitionType.Terminal]()
            or self.type_.value() is materialize[TransitionType.Nonterminal]()
            or self.type_.value() is materialize[TransitionType.Keyword]()
        )


struct DFATransition[dfa_origin: ImmutableOrigin](Copyable, Movable):
    var type_: TransitionType
    var to: Pointer[DFAState[dfa_origin], MutableAnyOrigin]

    fn __init__(
        out self,
        var type_: TransitionType,
        ref [MutableAnyOrigin]to: DFAState[dfa_origin],
    ):
        self.type_ = type_^
        self.to = Pointer(to=to)

    fn next_dfa(self) -> ref [self.to.origin] DFAState[dfa_origin]:
        return self.to[]


struct StackMode[dfa_origin: ImmutableOrigin](
    EqualityComparable, Identifiable, ImplicitlyCopyable, Movable, Writable
):
    alias Invalid = Self()
    alias Alternative = Self(0)
    alias LL = Self(1)

    var _v: Int
    var inner: UnsafePointer[Plan[dfa_origin], mut=False]

    # fn __merge_with__[
    #     other: __type_of(StackMode[_])
    # ](self, out result: StackMode[__origin_of(dfa_origin, other.dfa_origin)]):
    #     var plan = self.inner[].__merge_with__[other = Plan[other.dfa_origin]]()
    #     result = {
    #         v = self._v,
    #         plan = UnsafePointer(to=plan) if self.inner != {} else {},
    #     }

    fn __init__(
        out self,
        v: Int = -1,
        plan: UnsafePointer[Plan[dfa_origin], mut=False] = {},
    ):
        self.inner = plan
        self._v = v

    fn __eq__(self, other: Self) -> Bool:
        var inner_is_eq = (
            self.inner and other.inner and self.inner == other.inner
        ) or not (self.inner or other.inner)

        return self._v == other._v and inner_is_eq

    fn __is__(self, other: Self) -> Bool:
        return self._v == other._v

    fn __call__(
        self,
        plan: UnsafePointer[Plan[dfa_origin], mut=False] = {},
    ) -> Self:
        new_self = Self(self._v)
        if self is materialize[Self.Alternative]() and plan != {}:
            new_self.inner = plan
        elif self is materialize[Self.LL]():
            pass
        else:
            print("Invalid StackMode")
            sys.exit(1)
        return new_self^

    fn get(self) -> ref [StaticConstantOrigin] Plan[dfa_origin]:
        if self is materialize[Self.Alternative]():
            return self.inner[]

        print("Invalid getter for StackMode")
        sys.exit(1)
        return self.inner[]

    fn write_to(self, mut w: Some[Writer]):
        if self is materialize[Self.Alternative]():
            ref dfa = self.inner[].next_dfa()
            w.write(
                "Alternative(",
                dfa.from_rule,
                " #",
                dfa.list_index.inner,
                ")",
            )
        else:
            w.write("LL")


struct Push[dfa_origin: ImmutableOrigin](
    Copyable, EqualityComparable, Movable, Representable, Writable
):
    var node_type: InternalNonterminalType
    var _next_dfa: Pointer[DFAState[dfa_origin], origin=dfa_origin]
    var stack_mode: StackMode[dfa_origin]

    # fn __merge_with__[
    #     other: __type_of(Push[_])
    # ](self, out result: Push[__origin_of(dfa_origin, other.dfa_origin)]):
    #     # next_dfa = self._next_dfa[].__merge_with__[other=DFAState[other.dfa_origin]]()
    #     result = {
    #         node_type = self.node_type,
    #         next_dfa = self._next_dfa,
    #         stack_mode = self.stack_mode.__merge_with__[
    #             other = StackMode[result.dfa_origin]
    #         ](),
    #     }

    fn __init__(
        out self,
        node_type: InternalNonterminalType,
        ref [dfa_origin]next_dfa: DFAState[dfa_origin],
        stack_mode: StackMode[dfa_origin],
    ):
        self.node_type = node_type
        self._next_dfa = Pointer(to=next_dfa)
        self.stack_mode = stack_mode

    fn __eq__(self, other: Self) -> Bool:
        return (
            self.node_type == other.node_type
            and self._next_dfa == other._next_dfa
            and self.stack_mode == other.stack_mode
        )

    fn write_to(self, mut w: Some[Writer]):
        ref dfa = self.next_dfa()
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

    fn next_dfa(self) -> ref [self._next_dfa.origin] DFAState[dfa_origin]:
        return self._next_dfa[]


struct Plan[
    dfa_origin: ImmutableOrigin,
    next_origin: ImmutableOrigin = ImmutableAnyOrigin,
](Copyable, EqualityComparable, Movable, Writable):
    var pushes: List[Push[dfa_origin]]
    var _next_dfa: Pointer[DFAState[dfa_origin], next_origin]
    var type_: InternalSquashedType
    var mode: PlanMode
    var debug_text: StaticString

    # fn __merge_with__[
    #     other: __type_of(Plan[_])
    # ](self, out result: Plan[__origin_of(dfa_origin, other.dfa_origin)]):
    #     pushes: List[Push[result.dfa_origin]] = [
    #         v.__merge_with__[other = Push[result.dfa_origin]]()
    #         for v in self.pushes
    #     ]
    #     result = {
    #         pushes = pushes^,
    #         next_dfa = self._next_dfa[],
    #         type_ = self.type_,
    #         mode = self.mode,
    #         debug_text = self.debug_text,
    #     }

    fn __init__(
        out self,
        var pushes: List[Push[dfa_origin]],
        ref [next_origin]next_dfa: DFAState[dfa_origin],
        type_: InternalSquashedType,
        mode: PlanMode,
        debug_text: StaticString,
    ):
        self.pushes = pushes^
        self._next_dfa = Pointer(to=next_dfa)
        self.type_ = type_
        self.mode = mode
        self.debug_text = debug_text

    fn __eq__(self, other: Self) -> Bool:
        return (
            self.pushes == other.pushes
            and self._next_dfa == other._next_dfa
            and self.type_ == other.type_
        )

    fn write_to(self, mut w: Some[Writer]):
        ref _dfa = self.next_dfa()
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

    fn next_dfa(self) -> ref [next_origin] DFAState[dfa_origin]:
        return self._next_dfa[]


@fieldwise_init
struct Keywords(Copyable, Movable):
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


@fieldwise_init
struct RuleAutomaton[dfa_origin: ImmutableOrigin](Copyable, Movable):
    var type_: InternalNonterminalType
    var nfa_states: List[NFAState]
    var dfa_states: List[DFAState[dfa_origin]]  # sould be a Box?
    var name: StaticString
    var node_may_be_ommited: Bool
    var nfa_end_id: NFAStateId
    var no_transition_dfa_id: Optional[DFAStateId]
    var fallback_plans: List[Plan[dfa_origin]]  # Should be a Box?
    var does_error_recovery: Bool

    fn __init__(out self):
        self.type_ = {}
        self.nfa_states = {}
        self.dfa_states = {}
        self.name = {}
        self.node_may_be_ommited = {}
        self.nfa_end_id = {}
        self.no_transition_dfa_id = {}
        self.fallback_plans = {}
        self.does_error_recovery = {}

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

        if rule is materialize[Rule.Identifier]():
            var string = rule.get[StaticString]()
            var start, end = self.new_nfa_states()
            var t = terminal_map.get(string)
            if t:
                self.add_transition(
                    start,
                    end,
                    materialize[TransitionType.Terminal]()(
                        terminal=t.value(), string=string
                    ),
                )
            elif nonterminal_map.get(string):
                var nt = nonterminal_map.get(string)
                self.add_transition(
                    start,
                    end,
                    materialize[TransitionType.Nonterminal]()(
                        nonterminal=nt.value()
                    ),
                )
            else:
                print(
                    "No terminal / nonterminal found for",
                    string,
                    "; token map =",
                    terminal_map.__str__(),
                    "; node map =",
                    nonterminal_map.__str__(),
                )
                sys.exit(1)

            return (start, end)

        elif rule is Rule.Keyword:
            var string = rule.get[StaticString]()
            var start, end = self.new_nfa_states()
            self.add_transition(
                start, end, TransitionType.Keyword(string=string)
            )
            keywords.add(string)
            return (start, end)

        elif rule is Rule.Or:
            var rules = rule.get[(Rule, Rule)]()
            var start, end = self.new_nfa_states()

            @parameter
            for i in range(2):
                var x, y = _build(self, rules[i])
                self.add_empty_transition(start, x)
                self.add_empty_transition(y, end)
            return (start, end)

        elif rule is Rule.Maybe:
            var rule1 = rule.get[Rule]()
            var start, end = _build(self, rule1)
            self.add_empty_transition(start, end)
            return (start, end)

        elif rule is Rule.Multiple:
            var rule1 = rule.get[Rule]()
            var start, end = _build(self, rule1)
            self.add_empty_transition(end, start)
            return (start, end)

        elif rule is Rule.NegativeLookahead:
            var rule1 = rule.get[Rule]()
            var start, end = _build(self, rule1)
            var new_start, new_end = self.new_nfa_states()
            self.add_transition(
                new_start, start, TransitionType.NegativeLookaheadStart
            )
            self.add_transition(end, new_end, TransitionType.LookaheadEnd)
            return (new_start, new_end)

        elif rule is Rule.PositiveLookahead:
            var rule1 = rule.get[Rule]()
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
            ref rule1, rule2 = rule.get[(Rule, Rule)]()
            var start1, end1 = _build(self, rule1)
            var start2, end2 = _build(self, rule2)
            # What is it doing here?
            self.add_empty_transition(end1, start2)
            return (start1, end2)

        elif rule is Rule.NodeMayBeOmmited:
            var _rule = rule.get[Rule]()
            self.node_may_be_ommited = True
            return _build(self, _rule)
        elif rule is Rule.DoesErrorRecovery:
            var _rule = rule.get[Rule]()
            self.does_error_recovery = True
            return _build(self, _rule)

        print("Invalid Rule:", rule)
        sys.exit(1)
        return ({-1}, {-1})

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
            self.nfa_states.append(nfa_state^)
            return NFAStateId(len(self.nfa_states) - 1)

        return new(), new()

    fn add_transition(
        mut self,
        start: NFAStateId,
        to: NFAStateId,
        type_: Optional[TransitionType],
    ):
        self.nfa_state_mut(start).transitions.append(NFATransition(type_, to))

    fn add_empty_transition(mut self, start: NFAStateId, to: NFAStateId):
        self.add_transition(start, to, None)

    fn group_nfas(self, nfa_state_ids: List[NFAStateId]) -> Set[NFAStateId]:
        var set_ = {v for v in nfa_state_ids}
        for nfa_state_id in nfa_state_ids:
            for transition in self.nfa_state(nfa_state_id).transitions:
                if not transition.type_:
                    set_.add(transition.to)
                    if transition.to not in nfa_state_ids:
                        lst = [v for v in set_]
                        set_.update(self.group_nfas(lst^))

        return set_^

    fn nfa_to_dfa(
        mut self,
        starts: List[NFAStateId],
        end: NFAStateId,
        from_alternative_list_index: Optional[DFAStateId],
    ) -> ref [self.dfa_states] DFAState[dfa_origin]:
        """TODO: Check if this correctly handles the origins."""
        var grouped_nfas = self.group_nfas(starts)
        for ref dfa_state in self.dfa_states:
            if dfa_state.nfa_set == grouped_nfas:
                return dfa_state

        var some_is_end = [
            self.nfa_state(nfa_id).is_lookahead_end() for nfa_id in grouped_nfas
        ]
        var is_final = end in grouped_nfas and any(some_is_end)

        dfa_state = DFAState[dfa_origin](
            nfa_set=grouped_nfas^,
            is_final=is_final,
            is_calculated=False,
            list_index=DFAStateId(len(self.dfa_states)),
            from_alternative_list_index=from_alternative_list_index,
            node_may_be_omitted=self.node_may_be_ommited,
            from_rule=self.name,
            transition_to_plan=FastLookupTransitions[dfa_origin].new_empty(),
            transitions={},
        )

        self.dfa_states.append(dfa_state^)
        return self.dfa_states[-1]

    fn construct_powerset(mut self, start: NFAStateId, end: NFAStateId):
        ref dfa = self.nfa_to_dfa([start], end, None)
        self.construct_powerset_for_dfa(
            # using pointer to erase self mutable reference twice
            UnsafePointer[origin=MutableAnyOrigin](to=dfa)[],
            end,
        )

    fn construct_powerset_for_dfa(
        mut self,
        mut state: DFAState[dfa_origin],
        end: NFAStateId,
    ):
        # ref state = dfa[]
        if state.is_calculated:
            return

        var grouped_transitions = Dict[TransitionType, List[NFAStateId]]()
        nfa_list = [nfa for nfa in state.nfa_set]

        @parameter
        fn s(a: NFAStateId, b: NFAStateId) -> Bool:
            return a.inner < b.inner

        sort[s](nfa_list)

        for nfa_state_id in nfa_list:
            ref n = self.nfa_state(nfa_state_id)
            for transition in n.transitions:
                if transition.type_:
                    # TODO: Verify this logic.
                    ref t = transition.type_.value()
                    ref state_ids = grouped_transitions.setdefault(t, [])
                    if transition.is_terminal_nonterminal_or_keyword():
                        state_ids.append(transition.to)
                    else:
                        state_ids = [transition.to]

        var transitions = [
            DFATransition(it.key.copy(), self.nfa_to_dfa(it.value, end, None))
            for it in grouped_transitions.items()
        ]

        state.transitions = transitions.copy()
        state.is_calculated = True
        for ref transition in transitions:
            self.construct_powerset_for_dfa(transition.to[], end)

        state.is_final |= any(
            [
                t.type_ is TransitionType.NegativeLookaheadStart
                and search_lookahead_end(t.next_dfa()).is_final
                for t in state.transitions
            ]
        )

    fn add_no_transition_dfa_if_necessary(mut self):
        # var any_negative = any(
        #     [
        #         any(
        #             [
        #                 t.type_
        #                 and t.type_.value()
        #                 is TransitionType.NegativeLookaheadStart
        #                 for t in v.transitions
        #             ]
        #         )
        #         for v in self.nfa_states
        #     ]
        # )
        var any_negative = False
        for st in self.nfa_states:
            for t in st.transitions:
                if (
                    t.type_
                    and t.type_.value() is TransitionType.NegativeLookaheadStart
                ):
                    any_negative = True
                    break
            if any_negative:
                break

        if any_negative:
            var list_index = DFAStateId(len(self.dfa_states))
            var dfa_state = DFAState[dfa_origin](
                nfa_set={},
                is_final=False,
                is_calculated=True,
                list_index=list_index,
                from_alternative_list_index=None,
                node_may_be_omitted=self.node_may_be_ommited,
                from_rule=self.name,
                transition_to_plan=FastLookupTransitions[
                    dfa_origin
                ].new_empty(),
                transitions={},
            )
            self.dfa_states.append(dfa_state^)
            self.no_transition_dfa_id = list_index

    # TODO: MISSING
    # illustrate_dfa


fn generate_automatons[
    dfa_origin: ImmutableOrigin
](
    nonterminal_map: InternalStrToNode,
    terminal_map: InternalStrToToken,
    rules: RuleMap,
    soft_keywords: SoftKeywords,
) -> (Automatons[dfa_origin], Keywords):
    var keywords = Keywords(counter=len(terminal_map), keywords={})
    var automatons = Dict[InternalNonterminalType, RuleAutomaton[dfa_origin]]()

    for it in rules.items():
        ref internal_type = it.key
        ref rule_name, rule = it.value

        var automaton = RuleAutomaton[dfa_origin](
            type_=internal_type,
            name=rule_name,
            nfa_states={},
            dfa_states={},
            node_may_be_ommited={},
            nfa_end_id={},
            no_transition_dfa_id={},
            fallback_plans={},
            does_error_recovery={},
        )

        var start, end = automaton.build(
            nonterminal_map, terminal_map, keywords, rule
        )
        automaton.nfa_end_id = end
        automaton.construct_powerset(start, end)
        automaton.add_no_transition_dfa_if_necessary()
        automatons[internal_type] = automaton^

    var terminal_count = keywords.counter

    var first_plans = Dict[InternalNonterminalType, FirstPlan[dfa_origin]]()

    for ref it in automatons.items():
        ref rule_label = it.key
        create_first_plans(
            nonterminal_map,
            keywords,
            soft_keywords,
            first_plans,
            automatons,
            rule_label,
        )

        ref automaton = it.value
        if automaton.dfa_states[0].is_final:
            print(
                "The rule ",
                automaton.name,
                " must not have an empty production",
            )
            sys.exit(1)

        ref rl = first_plans.get(rule_label).value()
        if rl is materialize[FirstPlan[dfa_origin].Calculated]():
            ref plans, _ = rl.get()
            automaton.dfa_states[0].transition_to_plan = FastLookupTransitions[
                dfa_origin
            ].from_plans(terminal_count, plans.copy())
        else:
            print("Unreachable code while generating automatons.")
            sys.exit(1)

    for ref it in automatons.items():
        ref rule_label = it.key
        ref automaton = it.value
        for i in range(1, len(automaton.dfa_states)):
            ref plans, _ = plans_for_dfa(
                nonterminal_map,
                keywords,
                soft_keywords,
                automatons,
                first_plans,
                rule_label,
                DFAStateId(i),
                False,
            )
            automaton.dfa_states[i].transition_to_plan = FastLookupTransitions[
                dfa_origin
            ].from_plans(terminal_count, plans)

        for i in range(1, len(automaton.dfa_states)):
            var left_recursion_plans = create_left_recursion_plans[dfa_origin](
                automatons, rule_label, DFAStateId(i), first_plans
            )
            ref dfa = automaton.dfa_states[i]
            if len(dfa.transition_to_plan.inner) == 0:
                dfa.transition_to_plan = FastLookupTransitions[
                    dfa_origin
                ].from_plans(terminal_count, left_recursion_plans)
            else:
                dfa.transition_to_plan.extend(left_recursion_plans)

    return (automatons^, keywords^)


fn create_first_plans[
    dfa_origin: ImmutableOrigin
](
    nonterminal_map: InternalStrToNode,
    keywords: Keywords,
    soft_keywords: SoftKeywords,
    mut first_plans: FirstPlans[dfa_origin],
    mut automatons: Automatons[dfa_origin],
    automaton_key: InternalNonterminalType,
):
    if not first_plans.get(automaton_key):
        first_plans[automaton_key] = materialize[
            FirstPlan[dfa_origin].Calculating
        ]()()
        ref plans, is_left_recursive = plans_for_dfa(
            nonterminal_map,
            keywords,
            soft_keywords,
            automatons,
            first_plans,
            automaton_key,
            DFAStateId(0),
            True,
        )
        if is_left_recursive and len(plans) == 0:
            print(
                (
                    "The grammar contains left recursion without an alternative"
                    " for rule"
                ),
                nonterminal_to_str(nonterminal_map, automaton_key),
            )

        first_plans[automaton_key] = materialize[
            FirstPlan[dfa_origin].Calculated
        ]()(plans=plans.copy(), is_left_recursive=is_left_recursive)


fn plans_for_dfa[
    dfa_origin: ImmutableOrigin
](
    nonterminal_map: InternalStrToNode,
    keywords: Keywords,
    soft_keywords: SoftKeywords,
    mut automatons: Automatons[dfa_origin],
    mut first_plans: FirstPlans[dfa_origin],
    automaton_key: InternalNonterminalType,
    dfa_id: DFAStateId,
    is_first_plan: Bool,
) -> (SquashedTransitions[dfa_origin], Bool):
    var conflict_tokens = Set[InternalSquashedType]()
    var conflict_transitions = Set[TransitionType]()

    var plans = Dict[
        InternalSquashedType, (DFATransition[dfa_origin], Plan[dfa_origin])
    ]()
    var is_left_recursive = False

    ref dfa_state = automatons.setdefault(automaton_key, {}).dfa_states[
        dfa_id.inner
    ]

    for transition in dfa_state.transitions:
        ref ttype = transition.type_
        if ttype is TransitionType.Terminal:
            ref type_, debug_text = ttype.get[
                (InternalTerminalType, StaticString)
            ]()
            var t = type_.to_squashed()

            @parameter
            fn new_plan() -> Plan[dfa_origin]:
                return Plan[dfa_origin](
                    pushes=[],
                    next_dfa=transition.to[],
                    type_=t,
                    debug_text=debug_text,
                    mode=PlanMode.LL,
                )

            add_if_no_conflict[dfa_origin, new_plan](
                plans,
                conflict_transitions,
                conflict_tokens,
                transition.copy(),
                t,
                # new_plan,
            )

            try:
                ref kws = soft_keywords[type_]
                for kw in kws:
                    var soft_keyword_type = keywords.squashed(kw).value()
                    add_if_no_conflict[dfa_origin, new_plan](
                        plans,
                        conflict_transitions,
                        conflict_tokens,
                        DFATransition(
                            type_=TransitionType.Keyword(string=kw),
                            to=transition.to[],
                        ),
                        soft_keyword_type,
                        # create_plan,
                    )
            except:
                pass

        elif ttype is TransitionType.Nonterminal:
            ref node_id = ttype.get[InternalNonterminalType]()
            if is_first_plan:
                try:
                    if (
                        first_plans[node_id]
                        is materialize[FirstPlan[dfa_origin].Calculating]()
                    ):
                        if node_id != automaton_key:
                            print(
                                (
                                    "Indirect left recursion not supported (in"
                                    " rule "
                                ),
                                nonterminal_to_str(
                                    nonterminal_map, automaton_key
                                ),
                                ")",
                            )
                            sys.exit(1)
                        is_left_recursive = True
                        continue
                except:
                    pass

                create_first_plans(
                    nonterminal_map,
                    keywords,
                    soft_keywords,
                    first_plans,
                    automatons,
                    node_id,
                )

            try:
                ref fp = first_plans[node_id]
                if fp is materialize[FirstPlan[dfa_origin].Calculated]():
                    ref transitions = fp.get()[0]
                    for it in transitions.items():
                        ref t = it.key
                        # ref nested_plan = it.value

                        @parameter
                        fn create_plan() -> Plan[dfa_origin]:
                            return nest_plan(
                                it.value,  # this is nested_plan, but I removed to get rid of a warning
                                node_id,
                                transition.to,
                                StackMode[dfa_origin].LL,
                            )

                        add_if_no_conflict[dfa_origin, create_plan](
                            plans,
                            conflict_transitions,
                            conflict_tokens,
                            transition.copy(),
                            t,
                            # create_plan,
                        )

                elif fp is materialize[FirstPlan[dfa_origin].Calculating]():
                    print("this should be unreachable")
                    sys.exit(1)
            except:
                pass

        elif ttype is TransitionType.Keyword:
            ref keyword = ttype.get[StaticString]()
            var t = keywords.squashed(keyword).value()

            @parameter
            fn create_other_plan() -> Plan[dfa_origin]:
                return Plan[dfa_origin](
                    pushes=[],
                    next_dfa=transition.to[],
                    type_=t,
                    debug_text=keyword,
                    mode=PlanMode.LL,
                )

            add_if_no_conflict[dfa_origin, create_other_plan](
                plans,
                conflict_transitions,
                conflict_tokens,
                transition.copy(),
                t,
                # create_plan,
            )

        elif ttype is TransitionType.PositiveLookaheadStart:
            ref next_dfa, peek_terminals = calculate_peek_dfa(
                keywords, transition
            )
            for t in peek_terminals:
                ref ndfa = next_dfa[]
                plans[t] = (
                    transition.copy(),
                    Plan[dfa_origin](
                        debug_text="positive lookahead",
                        mode=PlanMode.PositivePeek,
                        next_dfa=next_dfa[],
                        pushes=[],
                        type_=t,
                    ),
                )
        elif ttype is TransitionType.NegativeLookaheadStart:
            ref next_dfa, peek_terminals = calculate_peek_dfa(
                keywords, transition
            )
            var next_plans = plans_for_dfa(
                nonterminal_map,
                keywords,
                soft_keywords,
                automatons,
                first_plans,
                automaton_key,
                next_dfa[].list_index,
                is_first_plan,
            )[0].copy()
            for t in peek_terminals:
                try:
                    ref automaton = automatons[automaton_key]
                    ref empty_dfa_id = automaton.no_transition_dfa_id.value()
                    ref dfa_state = automaton.dfa_states[empty_dfa_id.inner]
                    next_plans[t] = Plan[dfa_origin](
                        debug_text="Negative lookahead abort",
                        mode=PlanMode.LL,
                        next_dfa=dfa_state,
                        pushes=[],
                        type_=t,
                    )
                except:
                    pass

            plans |= {
                it.key: (transition.copy(), it.value.copy())
                for it in next_plans.items()
            }
        elif ttype is TransitionType.LookaheadEnd:
            continue

    for c in conflict_tokens:
        if c in plans:
            print("Assertion error on plans_for_dfa")
            sys.exit(1)

    var result = {it.key: it.value[1].copy() for it in plans.items()}

    if len(conflict_tokens) > 0:
        ref automaton = automatons.setdefault(automaton_key, {})
        ref generated_dfa_ids, end = split_tokens(
            automaton, dfa_state.copy(), conflict_transitions
        )
        var t = automaton.type_

        for dfa_id in reversed(generated_dfa_ids):
            ref new_plans, left_recursive = plans_for_dfa(
                nonterminal_map,
                keywords,
                soft_keywords,
                automatons,
                first_plans,
                automaton_key,
                dfa_id,
                is_first_plan,
            )

            if left_recursive:
                print("Assert error on left_recursive")
                sys.exit(1)

            for it in new_plans.items():
                ref transition = it.key
                var new_plan = it.value.copy()
                if transition in conflict_tokens:
                    try:
                        var fallback_plan = result.pop(transition)
                        ref automaton = automatons.setdefault(automaton_key, {})
                        automaton.fallback_plans.append(fallback_plan^)
                        new_plan = nest_plan(
                            new_plan,
                            t,
                            Pointer[origin=MutableAnyOrigin](to=end[]),
                            StackMode[dfa_origin].Alternative(
                                plan=UnsafePointer(
                                    to=automaton.fallback_plans.unsafe_get(
                                        len(automaton.fallback_plans) - 1
                                    )
                                )
                            ),
                        )
                    except:
                        pass

                    result[transition] = new_plan^
    return (result^, is_left_recursive)


fn add_if_no_conflict[
    dfa_origin: ImmutableOrigin,
    create_plan: fn () capturing -> Plan[dfa_origin],
](
    mut plans: Dict[
        InternalSquashedType, (DFATransition[dfa_origin], Plan[dfa_origin])
    ],
    mut conflict_transitions: Set[TransitionType],
    mut conflict_tokens: Set[InternalSquashedType],
    var transition: DFATransition[dfa_origin],
    token: InternalSquashedType,
    # create_plan: fn () capturing -> Plan,
):
    if token in conflict_tokens:
        conflict_transitions.add(transition.type_)
    else:
        try:
            ref t_x = plans[token][0]
            if t_x.type_ != transition.type_:
                _ = plans.pop(token)
                conflict_tokens.add(token)
                conflict_transitions.add(transition.type_)
                conflict_transitions.add(t_x.type_)
        except:
            pass

        plans[token] = (transition^, create_plan())


fn create_left_recursion_plans[
    dfa_origin: ImmutableOrigin
](
    automatons: Automatons[dfa_origin],
    automaton_key: InternalNonterminalType,
    dfa_id: DFAStateId,
    first_plans: FirstPlans[dfa_origin],
) -> SquashedTransitions[dfa_origin]:
    var plans = Dict[InternalSquashedType, Plan[dfa_origin]]()
    ref automaton = automatons.get(automaton_key, {})
    ref dfa_state = automaton.dfa_states[dfa_id.inner]

    if dfa_state.is_final and not dfa_state.is_lookahead_end():
        ref first_plan = first_plans.get(automaton.type_).value()
        if first_plan is materialize[FirstPlan[dfa_origin].Calculated]():
            ref is_left_recursive = first_plan.get()[1]
            if is_left_recursive:
                for transition in automaton.dfa_states[0].transitions:
                    if (
                        transition.type_ is TransitionType.Nonterminal
                        and transition.type_.get[InternalNonterminalType]()
                        == automaton.type_
                    ):
                        for i, opt_p in enumerate(
                            transition.next_dfa().transition_to_plan.inner
                        ):
                            if not opt_p:
                                continue
                            var t = InternalSquashedType(i)
                            ref p = opt_p.value()
                            if t in plans:
                                print(
                                    "Ambiguous:",
                                    dfa_state.from_rule,
                                    (
                                        "contains left recursion with"
                                        " alternatives!"
                                    ),
                                )
                            var dfa_state_ptr = Pointer(to=p.next_dfa())
                            plans[t] = Plan[dfa_origin](
                                pushes=p.pushes.copy(),
                                next_dfa=p.next_dfa(),
                                type_=t,
                                debug_text=p.debug_text,
                                mode=PlanMode.LeftRecursive,
                            )

    return plans^


fn nest_plan[
    dfa_origin: ImmutableOrigin,
    next_origin: ImmutableOrigin,
](
    plan: Plan[dfa_origin],
    new_node_id: InternalNonterminalType,
    next_dfa: Pointer[DFAState[dfa_origin], next_origin],
    mode: StackMode[dfa_origin],
) -> Plan[dfa_origin, next_origin]:
    var pushes = plan.pushes.copy()
    pushes.insert(
        0,
        Push[dfa_origin](
            node_type=new_node_id,
            next_dfa=plan.next_dfa(),
            stack_mode=mode,
        ),
    )
    return Plan(
        pushes=pushes^,
        next_dfa=next_dfa[],
        type_=plan.type_,
        debug_text=plan.debug_text,
        mode=PlanMode.LL,
    )


fn calculate_peek_dfa[
    dfa_origin: ImmutableOrigin
](keywords: Keywords, transition: DFATransition[dfa_origin]) -> (
    Pointer[DFAState[dfa_origin], MutableAnyOrigin],
    List[InternalSquashedType],
):
    ref dfa = transition.next_dfa()
    ref lookahead_end = dfa.transitions[0].next_dfa()

    debug_assert(lookahead_end.is_lookahead_end())
    debug_assert(len(lookahead_end.transitions) == 1)

    ref next_dfa = lookahead_end.transitions[0].next_dfa()

    var terminals = List[InternalSquashedType]()
    for transition in dfa.transitions:
        if transition.type_ is TransitionType.Terminal:
            var type_ = transition.type_.get[InternalTerminalType]()
            terminals.append(type_.to_squashed())
        elif transition.type_ is TransitionType.Keyword:
            var keyword = transition.type_.get[StaticString]()
            terminals.append(keywords.squashed(keyword).value())
        else:
            print("Only terminals lookaheads are allowed")
            sys.exit(1)

    return (Pointer(to=next_dfa), terminals^)


fn search_lookahead_end[
    o: Origin, dfa_origin: ImmutableOrigin
](ref [o]dfa_state: DFAState[dfa_origin]) -> ref [o] DFAState[dfa_origin]:
    var already_checked = Set[DFAStateId]()
    already_checked.add(dfa_state.list_index)

    @parameter
    fn search[
        o: Origin, dfa_origin: ImmutableOrigin
    ](
        mut already_checked: Set[DFAStateId],
        ref [o]dfa_state: DFAState[dfa_origin],
    ) -> ref [o] DFAState[dfa_origin]:
        for transition in dfa_state.transitions:
            if transition.type_ is TransitionType.LookaheadEnd:
                return transition.next_dfa()
            elif (
                transition.type_ is TransitionType.PositiveLookaheadStart
                or transition.type_ is TransitionType.NegativeLookaheadStart
            ):
                print("Unimplemented lookahead end search")
                sys.exit(1)
            else:
                ref to_dfa = transition.next_dfa()
                if to_dfa.list_index not in already_checked:
                    already_checked.add(to_dfa.list_index)
                    return search(already_checked, to_dfa)
        print("This should be unreachable.")
        sys.exit(1)

        # NOTE: This never runs
        return dfa_state.transitions[0].next_dfa()

    return search(already_checked, dfa_state)


fn split_tokens[
    dfa_origin: ImmutableOrigin
](
    mut automaton: RuleAutomaton[dfa_origin],
    dfa: DFAState[dfa_origin],
    conflict_transitions: Set[TransitionType],
) -> (
    List[DFAStateId],
    Pointer[DFAState[dfa_origin], __origin_of(automaton.dfa_states)],
):
    var transition_to_nfas = Dict[TransitionType, List[NFAStateId]]()
    var nfas = [v for v in dfa.nfa_set]

    @parameter
    fn sort_fn(v: NFAStateId, v2: NFAStateId) -> Bool:
        return v.inner > v2.inner

    sort[cmp_fn=sort_fn](nfas)

    for nfa_id in nfas:
        ref nfa = automaton.nfa_states[nfa_id.inner]
        for transition in nfa.transitions:
            ref opt_t = transition.type_
            if opt_t and opt_t.value() in conflict_transitions:
                t = opt_t.value()
                try:
                    ref lst = transition_to_nfas[t]
                    lst.append(nfa_id)
                except:
                    transition_to_nfas[t] = [nfa_id]

    var generated_dfa_ids = List[DFAStateId]()
    ref end_dfa = automaton.nfa_to_dfa(
        [automaton.nfa_end_id], automaton.nfa_end_id, None
    )

    var as_list = [t.copy() for t in transition_to_nfas.values()]

    @parameter
    fn sort_transition(v: List[NFAStateId], v2: List[NFAStateId]) -> Bool:
        return v[0].inner > v2[0].inner

    while len(as_list) > 0:
        sort[cmp_fn=sort_transition](as_list)
        var new_dfa_nfa_ids = List[NFAStateId]()
        if len(as_list) > 1:
            var must_be_smaller = as_list[1][0]
            if len(as_list[0]) == 0:
                print(
                    "This should not be possible.Assertion Error on"
                    " automaton.split_tokens fn."
                )
                sys.exit(1)
            while len(as_list[0]) > 0:
                var nfa_id = as_list[0][0]
                if nfa_id == must_be_smaller:
                    print("nfa_id should be distinct than must_be_smaller")
                    sys.exit(1)
                if nfa_id.inner > must_be_smaller.inner:
                    break
                new_dfa_nfa_ids.append(as_list[0].pop(0))

            if len(as_list[0]) == 0:
                _ = as_list.pop(0)

        else:
            new_dfa_nfa_ids.extend(as_list.pop())

        if len(new_dfa_nfa_ids) == 0:
            print("new_dfa_nfa_ids should not be empty")
            sys.exit(1)

        ref new_dfa = automaton.nfa_to_dfa(
            new_dfa_nfa_ids, automaton.nfa_end_id, dfa.list_index
        )
        automaton.construct_powerset_for_dfa(
            UnsafePointer[origin=MutableAnyOrigin](to=new_dfa)[],
            automaton.nfa_end_id,
        )

        for generated_dfa_id in reversed(generated_dfa_ids):
            ref higher_prio_dfa = automaton.dfa_states[generated_dfa_id.inner]
            var any_eq = False
            for tt in higher_prio_dfa.transitions:
                for t in new_dfa.transitions:
                    if t.type_ == tt.type_:
                        any_eq = True
                        break

                if any_eq:
                    break

            if any_eq:
                panic_if_unreachable_transition(dfa, higher_prio_dfa)

        generated_dfa_ids.append(new_dfa.list_index)

    return (generated_dfa_ids^, Pointer(to=end_dfa))


fn panic_if_unreachable_transition(original_dfa: DFAState, split_dfa: DFAState):
    @parameter
    fn check(
        mut already_checked: List[DFAStateId],
        original_dfa: DFAState,
        split_dfa: DFAState,
    ):
        already_checked.append(split_dfa.list_index)
        var t1 = [t.type_ for t in original_dfa.transitions]
        var t2 = [t.type_ for t in split_dfa.transitions]
        if t1 != t2 and split_dfa.is_final:
            print(
                "Find and unreachable alternative in the rule",
                original_dfa.from_rule,
            )
            sys.exit(1)

        for t in split_dfa.transitions:
            ref dfa = t.next_dfa()
            if dfa.list_index not in already_checked:
                for t2 in original_dfa.transitions:
                    if t2.type_ == t.type_:
                        check(already_checked, t2.next_dfa(), dfa)

    var already_checked = List[DFAStateId]()
    check(already_checked, original_dfa, split_dfa)


fn nonterminal_to_str(
    nonterminal_map: InternalStrToNode, nonterminal: InternalNonterminalType
) -> StaticString:
    for it in nonterminal_map.items():
        if nonterminal == it.value:
            return it.key

    print("Something is very wrong, integer not found.", nonterminal)
    sys.exit(1)
    return {}


# TODO: Should implement iterator but I will iterate the inner list and ignore None values. That's all.
struct FastLookupTransitions[dfa_origin: ImmutableOrigin](Copyable, Movable):
    var inner: List[Optional[Plan[dfa_origin]]]

    fn __init__(out self):
        self.inner = {}

    fn __init__(out self, var value: List[Optional[Plan[dfa_origin]]]):
        self.inner = value^

    @staticmethod
    fn new_empty() -> Self:
        return Self()

    @staticmethod
    fn from_plans(
        terminal_count: UInt, transitions: SquashedTransitions
    ) -> Self:
        if terminal_count == 0:
            print("Invalid state for terminal count:", terminal_count)
            sys.exit(1)

        var lst: List[Optional[Plan[dfa_origin]]] = [
            None for _ in range(terminal_count)
        ]
        return Self(lst^)

    fn extend(mut self, other: SquashedTransitions[dfa_origin]):
        for it in other.items():
            ref index = it.key
            ref plan = it.value
            self.inner[index.inner] = Optional(plan.copy())

    fn lookup(
        self, index: InternalSquashedType
    ) -> ref [self.inner] Optional[Plan[dfa_origin]]:
        return self.inner[index.inner]
