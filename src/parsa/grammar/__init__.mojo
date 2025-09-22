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
    RuleMap,
    SoftKeywords,
    Squashable,
    StackMode,
    generate_automatons,
)

from parsa.grammar.mode_data import ModeData, ModeDataVariant

# from utils import Variant

# Backtracking??


alias NodeIndex = UInt32
alias CodeIndex = UInt32
alias CodeLength = UInt32


trait Token(Copyable, Writable):
    fn start_index(self) -> UInt32:
        ...

    fn lenth(self) -> UInt32:
        ...

    fn type_(self) -> InternalTerminalType:
        ...

    fn can_contain_syntax(self) -> Bool:
        ...


trait Tokenizer(Iterator):
    alias T: Token

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
    var automatons: Automatons[ImmutableOrigin.empty]
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
        I: Iterator
    ](
        self, code: StringSlice, tokens: I, start: InternalNonterminalType
    ) -> List[InternalNode]:
        _, _, idx = self.automatons._find_index(hash(start), start)
        ref automaton_rule = self.automatons._entries[idx].value().value

        var stack = Stack(start, automaton_rule.dfa_states[0], len(code))


struct BacktrackingPoint[fallback: ImmutableOrigin](Copyable, Movable):
    var tree_node_count: UInt
    var token_index: UInt
    var children_count: UInt
    var fallback_plan: Pointer[Plan[fallback], fallback]

    fn __init__(
        out self,
        tree_node_count: UInt,
        token_index: UInt,
        children_count: UInt,
        ref [fallback]fallback_plan: Plan[fallback],
    ):
        self.tree_node_count = tree_node_count
        self.token_index = token_index
        self.children_count = children_count
        self.fallback_plan = Pointer(to=fallback_plan)


struct StackNode[dfa_origin: ImmutableOrigin](Copyable, Movable):
    var node_id: InternalNonterminalType
    var tree_node_index: UInt
    var latest_child_node_index: UInt
    var dfa_state: Pointer[DFAState[dfa_origin], dfa_origin]
    var children_count: UInt

    var mode: ModeData[dfa_origin]
    var enabled_token_recording: Bool

    fn __init__(
        out self,
        node_id: InternalNonterminalType,
        tree_node_index: UInt,
        latest_child_node_index: UInt,
        ref [dfa_origin]dfa_state: DFAState[dfa_origin],
        children_count: UInt,
        var mode: ModeData[dfa_origin],
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


struct Stack[node_origin: ImmutableOrigin](Sized):
    var stack_nodes: List[StackNode[node_origin]]
    var tree_nodes: List[InternalNode]

    fn __init__(
        out self,
        var node_id: InternalNonterminalType,
        ref [node_origin]dfa_state: DFAState[node_origin],
        string_len: Int,
    ):
        self.stack_nodes = {capacity = 128}
        self.tree_nodes = {capacity = string_len // 4}
        self.push(
            node_id,
            0,
            dfa_state,
            0,
            ModeDataVariant.LL.new[node_origin](),
            0,
            False,
        )

    @always_inline
    fn tos(self) -> ref [self.stack_nodes[0]] StackNode[node_origin]:
        return self.stack_nodes.unsafe_get(len(self) - 1)

    @always_inline
    fn tos_mut(mut self) -> ref [self.stack_nodes[0]] StackNode[node_origin]:
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
        ref [node_origin]dfa_state: DFAState[node_origin],
        start: CodeIndex,
        var mode: ModeData[node_origin],
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
