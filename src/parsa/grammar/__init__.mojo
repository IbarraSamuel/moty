from parsa.automaton import (
    Automatons,
    DFAState,
    InternalNonterminalType,
    InternalSquashedType,
    InternalStrToNode,
    InternalStrToToken,
    InternalTerminalType,
    Keywords,
    Plan,
    PlanMode,
    PlanModeVariant,
    RuleMap,
    SoftKeywords,
    Squashable,
    StackMode,
    StackModeVariant,
    generate_automatons,
)

from parsa.grammar.mode_data import ModeData, ModeDataVariant
from parsa.backtracking import BacktrackingTokenizer

from os import abort

# from utils import Variant

# Backtracking??


alias NodeIndex = UInt32
alias CodeIndex = UInt32
alias CodeLength = UInt32


trait Token(Copyable, Movable, Writable):
    fn start_index(self) -> Int:
        ...

    fn length(self) -> Int:
        ...

    fn type_(self) -> InternalTerminalType:
        ...

    fn can_contain_syntax(self) -> Bool:
        ...


trait Tokenizer(Iterator):
    alias Element: Token

    fn __init__(out self, code: StringSlice):
        ...


struct InternalTree[code_origin: ImmutableOrigin]:
    var code: StringSlice[code_origin]
    var nodes: List[InternalNode]

    fn __init__(
        out self, code: StringSlice[code_origin], var nodes: List[InternalNode]
    ):
        self.code = code
        self.nodes = nodes^


@fieldwise_init
struct InternalNode(Copyable, Movable):
    var next_node_offset: NodeIndex
    var type_: InternalSquashedType
    var start_index: CodeIndex
    var length: CodeLength

    fn end_index(self) -> UInt32:
        return self.start_index + self.length


# NOT USED
struct CompressedNode:
    var next_node_offset: UInt8
    var type_: Int8
    var start_index: UInt16
    var length: UInt16


@fieldwise_init
struct Grammar[T: AnyType]:
    var terminal_map: Pointer[InternalStrToToken, StaticConstantOrigin]
    var nonterminal_map: Pointer[InternalStrToNode, StaticConstantOrigin]
    var automatons: Automatons
    var keywords: Keywords
    var soft_keywords: SoftKeywords

    fn __init__[
        token: Token
    ](
        out self: Grammar[token],
        rules: RuleMap,
        ref [StaticConstantOrigin]nonterminal_map: InternalStrToNode,
        ref [StaticConstantOrigin]terminal_map: InternalStrToToken,
        var soft_keywords: SoftKeywords,
    ):
        ref automatons, keywords = generate_automatons(
            nonterminal_map, terminal_map, rules, soft_keywords
        )
        return {
            Pointer(to=terminal_map),
            Pointer(to=nonterminal_map),
            automatons.copy(),
            keywords.copy(),
            soft_keywords^,
        }

    fn parse[
        I: Tokenizer
    ](
        self, code: StaticString, tokens: I, start: InternalNonterminalType
    ) -> List[InternalNode]:
        _, _, idx = self.automatons._find_index(hash(start), start)
        ref automaton_rule = self.automatons._entries[idx].value().value

        var stack = Stack(start, automaton_rule.dfa_states[0], len(code))
        var backtracking_tokenizer = BacktrackingTokenizer(tokens.copy())

        while len(stack) > 0:
            for token in backtracking_tokenizer:
                var transition: InternalSquashedType
                if token.can_contain_syntax():
                    var start = token.start_index()
                    var token_str = code[start : start + token.length()]
                    transition = self.keywords.squashed(token_str).or_else(
                        token.type_().to_squashed()
                    )
                else:
                    transition = token.type_().to_squashed()

                self.apply_transition(
                    stack, backtracking_tokenizer, transition, token
                )

            ref tos = stack.tos()
            var mode = tos.mode.copy()
            if tos.dfa_state[].is_final:
                self.end_of_node(stack, backtracking_tokenizer, mode^)
            else:
                self.error_recovery(stack, backtracking_tokenizer, None, None)

        return stack^.take_tree_nodes()

    @always_inline
    fn apply_transition[
        I: Tokenizer,
        dfa_state_o: ImmutableOrigin,
        fallback_plan_o: ImmutableOrigin,
    ](
        self,
        mut stack: Stack[dfa_state_o, fallback_plan_o],
        mut backtracking_tokenizer: BacktrackingTokenizer[I],
        transition: InternalSquashedType,
        token: I.Element,
    ):
        while True:
            ref tos = stack.tos()
            var is_final = tos.dfa_state[].is_final
            ref mode = tos.mode
            ref lkp = tos.dfa_state[].transition_to_plan.lookup(transition)
            if not lkp:
                if is_final:
                    self.end_of_node(stack, backtracking_tokenizer, mode.copy())
                else:
                    self.error_recovery(
                        stack,
                        backtracking_tokenizer,
                        Optional(transition),
                        Optional(token.copy()),
                    )
                    return
            else:
                ref plan = lkp.value()
                if PlanModeVariant.PositivePeek.matches(plan.mode):
                    ref tos_mut = stack.tos_mut()
                    tos_mut.dfa_state = Pointer[origin = stack.dfa_state_o](
                        to=plan.next_dfa()
                    )
                else:
                    self.apply_plan(stack, plan, token, backtracking_tokenizer)
                    break

    @always_inline
    fn end_of_node[
        dfa_state_o: ImmutableOrigin,
        fallback_plan_o: ImmutableOrigin,
        I: Tokenizer,
    ](
        self,
        mut stack: Stack[dfa_state_o, fallback_plan_o],
        mut backtracking_tokenizer: BacktrackingTokenizer[I],
        mode: ModeData[fallback_plan_o],
    ):
        if ModeDataVariant.LL.matches(mode):
            stack.pop_normal()
        if ModeDataVariant.Alternative.matches(mode):
            var old_tos = stack.stack_nodes.pop()
            ref tos = stack.tos_mut()
            tos.children_count = old_tos.children_count
            tos.latest_child_node_index = old_tos.latest_child_node_index
            if not tos.enabled_token_recording:
                backtracking_tokenizer.stop()
            debug_assert(tos.dfa_state[].is_final)

    fn error_recovery[
        I: Tokenizer
    ](
        self,
        mut stack: Stack,
        mut backtracking_tokenizer: BacktrackingTokenizer[I],
        transition: Optional[InternalSquashedType],
        token: Optional[I.Element],
    ):
        for i, node in enumerate(stack.stack_nodes):  # TODO: REVERSE
            if ModeDataVariant.Alternative.matches(node.mode):
                ref backtracking_point = ModeDataVariant.Alternative[node.mode]

                fn truncate(mut lst: List, i: Int):
                    # TODO: Verify if its' fine
                    for _ in range(len(lst) - i):
                        _ = lst.pop()

                truncate(stack.stack_nodes, i)
                truncate(stack.tree_nodes, backtracking_point.tree_node_count)

                ref tos = stack.tos_mut()
                tos.children_count = backtracking_point.children_count
                backtracking_tokenizer.reset(backtracking_point.token_index)
                ref t = backtracking_tokenizer.__next__()
                self.apply_plan(
                    stack,
                    backtracking_point.fallback_plan[],
                    t,
                    backtracking_tokenizer,
                )

                if not stack.tos().enabled_token_recording:
                    backtracking_tokenizer.stop()

                return

        if transition:
            ref transition_ref = transition.value()
            for nonterminal_id in (
                stack.tos().dfa_state[].nonterminal_transition_ids()
            ):
                # Unsafe get
                _, _, nont_idx = self.automatons._find_index(
                    hash(nonterminal_id), nonterminal_id
                )
                ref automaton = self.automatons._entries[nont_idx].value().value

                if automaton.does_error_recovery:
                    stack.calculate_previous_next_node()
                    ref token_ref = token.value()
                    stack.tree_nodes.append(
                        InternalNode(
                            next_node_offset=0,
                            type_=nonterminal_id.to_squashed().set_error_recovery_bit(),
                            start_index=token_ref.start_index(),
                            length=token_ref.length(),
                        )
                    )
                    stack.tree_nodes.append(
                        InternalNode(
                            next_node_offset=0,
                            type_=transition_ref.set_error_recovery_bit(),
                            start_index=token_ref.start_index(),
                            length=token_ref.length(),
                        )
                    )
                    return

        for i, node in enumerate(stack.stack_nodes):
            _, _, nid_idx = self.automatons._find_index(
                hash(node.node_id), node.node_id
            )
            ref automaton = self.automatons._entries[nid_idx].value().value
            if automaton.does_error_recovery:
                while len(stack.stack_nodes) > i:
                    var stack_node = stack.stack_nodes.pop()
                    update_tree_node_position(stack.tree_nodes, stack_node)
                    ref n = stack.tree_nodes[stack_node.tree_node_index]
                    n.type_ = n.type_.set_error_recovery_bit()

                if transition:
                    self.apply_transition(
                        stack,
                        backtracking_tokenizer,
                        transition.value(),
                        token.value(),
                    )

                return

        fn mapper(
            var n: StackNode[stack.dfa_state_o, stack.fallback_plan_o]
        ) -> StaticString:
            return n.dfa_state[].from_rule

        ref nodes = "".join([v for v in map[mapper](stack.stack_nodes)])
        var token_repr: String
        if token:
            token_repr = String("Some(", token.value(), ")")
        else:
            token_repr = "None"

        abort(
            String(
                "No error recovery function found with stack ",
                nodes,
                " and token: ",
                token_repr,
            )
        )

    @always_inline
    fn apply_plan[
        I: Tokenizer
    ](
        self,
        mut stack: Stack,
        ref plan: Plan,
        token: I.Element,
        mut backtracking_tokenizer: BacktrackingTokenizer[I],
    ):
        ref tos_mut = stack.stack_nodes[-1]
        tos_mut.dfa_state = Pointer[origin = stack.dfa_state_o](
            to=plan.next_dfa()
        )

        var start_index = token.start_index()

        if (
            PlanModeVariant.LeftRecursive.matches(plan.mode)
            and not tos_mut.can_omit_children()
        ):
            tos_mut.children_count = 1
            tos_mut.latest_child_node_index = tos_mut.tree_node_index + 1
            tos_mut.mode = ModeDataVariant.LL.new[stack.fallback_plan_o]()

            update_tree_node_position(stack.tree_nodes, tos_mut)

            ref old_node = stack.tree_nodes[tos_mut.tree_node_index]
            stack.tree_nodes.insert(
                tos_mut.tree_node_index,
                InternalNode(
                    next_node_offset=0,
                    type_=old_node.type_,
                    start_index=old_node.start_index,
                    length=0,
                ),
            )

        var enabled_token_recording = tos_mut.enabled_token_recording
        stack.calculate_previous_next_node()

        for push in plan.pushes:
            ref tos = stack.tos_mut()
            var children_count = tos.children_count
            tos.children_count += 1

            if StackModeVariant.LL.matches(push.stack_mode):
                stack.push(
                    push.node_type,
                    len(stack.tree_nodes),
                    push.next_dfa(),
                    start_index,
                    ModeDataVariant.LL.new[stack.fallback_plan_o](),
                    0,
                    enabled_token_recording,
                )

            elif StackModeVariant.Alternative.matches(push.stack_mode):
                var alternative_plan = StackModeVariant.Alternative[
                    push.stack_mode
                ].origin_cast[
                    stack.fallback_plan_o.mut, stack.fallback_plan_o
                ]()
                enabled_token_recording = True
                var backtracking_point = BacktrackingPoint(
                    tree_node_count=len(stack.tree_nodes),
                    token_index=backtracking_tokenizer.start(token),
                    fallback_plan=alternative_plan[],
                    children_count=children_count,
                )
                stack.push(
                    push.node_type,
                    stack.tos().tree_node_index,
                    push.next_dfa(),
                    start_index,
                    ModeDataVariant.Alternative.new(backtracking_point^),
                    children_count,
                    enabled_token_recording,
                )

            stack.tos_mut().latest_child_node_index = len(stack.tree_nodes)

        stack.tos_mut().children_count += 1
        stack.tree_nodes.append(
            InternalNode(
                next_node_offset=0,
                type_=plan.type_,
                start_index=start_index,
                length=token.length(),
            )
        )


struct BacktrackingPoint[fallback_plan_o: ImmutableOrigin](Copyable, Movable):
    var tree_node_count: UInt
    var token_index: UInt
    var children_count: UInt
    var fallback_plan: Pointer[Plan, fallback_plan_o]

    fn __init__(
        out self,
        tree_node_count: UInt,
        token_index: UInt,
        children_count: UInt,
        ref [fallback_plan_o]fallback_plan: Plan,
    ):
        self.tree_node_count = tree_node_count
        self.token_index = token_index
        self.children_count = children_count
        self.fallback_plan = Pointer(to=fallback_plan)


struct StackNode[
    dfa_state_o: ImmutableOrigin, fallback_plan_o: ImmutableOrigin
](Copyable, Movable):
    var node_id: InternalNonterminalType
    var tree_node_index: UInt
    var latest_child_node_index: UInt
    var dfa_state: Pointer[DFAState, dfa_state_o]
    var children_count: UInt

    var mode: ModeData[fallback_plan_o]
    var enabled_token_recording: Bool

    fn __init__(
        out self,
        node_id: InternalNonterminalType,
        tree_node_index: UInt,
        latest_child_node_index: UInt,
        ref [dfa_state_o]dfa_state: DFAState,
        children_count: UInt,
        var mode: ModeData[fallback_plan_o],
        enabled_token_recording: Bool,
    ):
        self.node_id = node_id
        self.tree_node_index = tree_node_index
        self.latest_child_node_index = latest_child_node_index
        self.dfa_state = Pointer(to=dfa_state)
        self.children_count = children_count
        self.mode = mode^
        self.enabled_token_recording = enabled_token_recording

    fn write_to(self, mut writer: Some[Writer]):
        writer.write(
            "StackNode(",
            "tree_node_index:",
            self.tree_node_index,
            ", latest_child_node_index:",
            self.latest_child_node_index,
            ", dfa_state: {name:",
            self.dfa_state[].from_rule,
            ", is_final:",
            self.dfa_state[].is_final,
            ", node_may_be_ommited:",
            self.dfa_state[].node_may_be_omitted,
            "}, children_count:",
            self.children_count,
            ", mode:",
            # self.mode,
            ", enabled_token_recording:",
            self.enabled_token_recording,
            ")",
        )

    @always_inline
    fn can_omit_children(self) -> Bool:
        return self.dfa_state[].node_may_be_omitted and self.children_count == 1


struct Stack[dfa_state_o: ImmutableOrigin, fallback_plan_o: ImmutableOrigin](
    Sized
):
    var stack_nodes: List[StackNode[dfa_state_o, fallback_plan_o]]
    var tree_nodes: List[InternalNode]

    fn __init__(
        out self: Stack[dfa_state_o, ImmutableOrigin.empty],
        var node_id: InternalNonterminalType,
        ref [dfa_state_o]dfa_state: DFAState,
        string_len: Int,
    ):
        self.stack_nodes = {capacity = 128}
        self.tree_nodes = {capacity = string_len // 4}
        self.push(
            node_id,
            0,
            dfa_state,
            0,
            ModeDataVariant.LL.new[self.fallback_plan_o](),
            0,
            False,
        )

    # HELPER
    fn take_tree_nodes(deinit self) -> List[InternalNode]:
        _ = self.stack_nodes^
        return self.tree_nodes^

    @always_inline
    fn tos(
        self,
    ) -> ref [self.stack_nodes[0]] StackNode[dfa_state_o, fallback_plan_o]:
        return self.stack_nodes.unsafe_get(len(self) - 1)

    @always_inline
    fn tos_mut(
        mut self,
    ) -> ref [self.stack_nodes[0]] StackNode[dfa_state_o, fallback_plan_o]:
        return self.stack_nodes.unsafe_get(len(self) - 1)

    @always_inline
    fn __len__(self) -> Int:
        return len(self.stack_nodes)

    @always_inline
    fn pop_normal(mut self):
        ref stack_node = self.stack_nodes.pop()
        if stack_node.can_omit_children():
            _ = self.tree_nodes.pop(stack_node.tree_node_index)
        else:
            debug_assert(stack_node.children_count >= 1)
            update_tree_node_position(self.tree_nodes, stack_node)

    @always_inline
    fn push(
        mut self,
        node_id: InternalNonterminalType,
        tree_node_index: Int,
        ref [dfa_state_o]dfa_state: DFAState,
        start: CodeIndex,
        var mode: ModeData[fallback_plan_o],
        children_count: Int,
        enabled_token_recording: Bool,
    ):
        if ModeDataVariant.LL.matches(mode):
            self.tree_nodes.append(
                InternalNode(0, node_id.to_squashed(), start, 0)
            )

        self.stack_nodes.append(
            StackNode(
                node_id,
                tree_node_index,
                0,
                dfa_state,
                children_count,
                mode^,
                enabled_token_recording,
            )
        )

    @always_inline
    fn calculate_previous_next_node(mut self):
        ref tos = self.stack_nodes.unsafe_get(len(self) - 1)
        var index = tos.latest_child_node_index

        var next = len(self.tree_nodes)

        if index != 0 and index < len(self.tree_nodes):
            self.tree_nodes.unsafe_get(index).next_node_offset = next - index

        tos.latest_child_node_index = next

    fn debug_tree(
        self,
        nonterminal_map: InternalStrToNode,
        terminal_map: InternalStrToToken,
    ) -> String:
        # TODO
        return {}


@always_inline
fn update_tree_node_position(
    mut tree_nodes: List[InternalNode], stack_node: StackNode
):
    ref last_tree_node = tree_nodes[-1]
    ref n = tree_nodes[stack_node.tree_node_index]
    n.length = last_tree_node.end_index() - n.start_index
