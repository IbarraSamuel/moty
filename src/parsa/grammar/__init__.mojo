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

from utils import Variant

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


struct Grammar[T: AnyType]:
    var terminal_map: Pointer[InternalStrToToken, StaticConstantOrigin]
    var nonterminal_map: Pointer[InternalStrToNode, StaticConstantOrigin]
    var automatons: Automatons
    var keywords: Keywords
    var soft_keywords: SoftKeywords

    fn __init__(
        out self,
        rules: RuleMap,
        ref [StaticConstantOrigin]nonterminal_map: InternalStrToNode,
        ref [StaticConstantOrigin]terminal_map: InternalStrToToken,
        var soft_keywords: SoftKeywords,
    ):
        ref automatons, keywords = generate_automatons(
            nonterminal_map, terminal_map, rules, soft_keywords
        )
        self.terminal_map = Pointer(to=terminal_map)
        self.nonterminal_map = Pointer(to=nonterminal_map)
        self.automatons = automatons.copy()
        self.keywords = keywords.copy()
        self.soft_keywords = soft_keywords^


alias ModeData[backtracking: ImmutableOrigin] = Variant[
    ModeDataAlternative[backtracking], ModeDataLL
]


struct ModeDataAlternative[backtracking: ImmutableOrigin](Copyable, Movable):
    var inner: BacktrackingPoint[backtracking]


struct ModeDataLL(Copyable, Movable):
    pass


struct BacktrackingPoint[fallback: ImmutableOrigin](Copyable, Movable):
    var tree_node_count: UInt
    var token_index: UInt
    var children_count: UInt
    var fallback_plan: Pointer[Plan, fallback]


struct StackNode[dfa_origin: ImmutableOrigin](Copyable, Movable):
    var node_id: InternalNonterminalType
    var tree_node_index: UInt
    var latest_child_node_index: UInt
    var dfa_state: Pointer[DFAState, dfa_origin]
    var children_count: UInt

    var mode: ModeData[dfa_origin]
    var enabled_token_recording: Bool

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


struct Stack[node_origin: ImmutableOrigin]:
    var stack_nodes: List[StackNode[node_origin]]
    var tree_nodes: List[InternalNode]
