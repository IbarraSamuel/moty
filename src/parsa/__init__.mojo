from pathlib import Path

alias struct_Grammar = """
struct {Grammar}:
    var internal_grammar: Grammar[{Token}]

    fn __init__(out self):
        var rules = Dict[...]
        {__parse_rules}
        {__parse_soft_keywords}
        self.internal_grammar = Grammar(rules, {NonterminalType}.map(), {TerminalType}.map(), soft_keywords)
    
    fn keywords[I: Iterator](self) -> __type_of(self.internal_grammar.keywords.keywords.keys()):
        return self.internal_grammar.keywords.keywords.keys()
    
    fn keywords_contain(self, keyword: StringSlice) -> Bool:
        return keyword in self.internal_grammar.keywords.keywords
    
    fn parse(self, code: String) -> {Tree}:
        var start = {NonterminalType}.map()["$first_node"]
        var nodes = self.internal_grammar.parse(code, {Tokenizer}(code), start)
        return {Tree}(internal_tree=InternalTree(code, nodes))


struct {Tree}(Copyable, Writable):
    var internal_tree: InternalTree

    fn __init__(out self):
        self.internal_tree = InternalTree(code="", nodes=List())

    fn as_code(self) -> StringSlice:
        self.internal_tree.code
    
    fn root_node[o: ImmutableOrigin](self) -> {Node}[o]:
        return self.node(0, self.internal_tree.nodes[0])

    @always_inline
    fn node[o: ImmutableOrigin](ref[o] self, index: NodeIndex, ref[o] internal_node: InternalNode) -> {Node}[o]:
        return {Node}(internal_tree=self.internal_tree, internal_node=internal_node, index=index)
    
    fn length(self) -> Int:
        len(self.internal_tree.nodes)
    
    fn nodes(self) -> Iterator:
        fn map_nodes(var arg: Tuple[Int, InternalNode]) -> {Node}:
            return self.node(NodeIndex(arg[0]), arg[1])
    
        return map[map_nodes](enumerate(self.internal_tree.nodes))
    
    fn node_by_index(self, index: NodeIndex) -> {Node}:
        return self.node(index, self.internal_tree.nodes[Int(index)])
    
    fn leaf_by_position(self, position: CodeIndex) -> {Node}:
        var nodes = self.internal_tree.nodes

        fn ppoint(node: __type_of(nodes[0])) -> Bool:
            return node.start_index <= position
        var index = nodes.partition_point[ppoint]()

        for i, node in reversed(enumerate(nodes[:index])):
            if nodes.type_.is_leaf():
                var node = self.node(NodeIndex(i), node)
                if node.end() < position:
                    var nl = node.next_leaf()
                    if nl:
                        return nl.value()
                return node
        
        var node = self.node(NodeIndex(len(nodes) - 1), nodes[-1])

        debug_assert(node.is_leaf())
        return node
    

    fn write_to(self, mut w: Some[Writer]):
        self.write("Tree(nodes:", self.nodes.__str__(), ")")

alias {grammar}: {Grammar} = {Grammar}()

"""


fn create_grammar[
    grammar: StringLiteral,
    Grammar: StringLiteral,
    Tree: StringLiteral,
    Node: StringLiteral,
    NodeType: StringLiteral,
    NonterminalType: StringLiteral,
    Tokenizer: StringLiteral,
    Token: StringLiteral,
    TerminalType: StringLiteral,
    soft_keywords: List[StaticString],
    first_node: StringLiteral,
    rules: List[StaticString],
]() -> String:
    alias _node = __create_node[
        Tree=Tree,
        Node=Node,
        NodeType=NodeType,
        NonterminalType=NonterminalType,
        TerminalType=TerminalType,
        first_node=first_node,
        rules_to_nodes=rules,
    ]()

    alias _parse_rules = __parse_rules[NonterminalType, first_node, rules]()
    alias _parse_soft_keywords = __parse_soft_keywords[
        TerminalType, soft_keywords
    ]()

    alias str_grammar = (
        struct_Grammar.as_string_slice()
        .replace("{grammar}", grammar)
        .replace("{Grammar}", Grammar)
        .replace("{Tree}", Tree)
        .replace("{Node}", Node)
        .replace("{NodeType}", NodeType)
        .replace("{NonterminalType}", NonterminalType)
        .replace("{Tokenizer}", Tokenizer)
        .replace("{Token}", Token)
        .replace("{TerminalType}", TerminalType)
        .replace("{__parse_rules}", _parse_rules)
        .replace("{__parse_soft_keywords}", _parse_soft_keywords)
    )

    return str_grammar


# fn __parse_next_identifier[input: StringLiteral, neg: () = (), rule: StringLiteral]() -> String:
#     return "RuleVariant.Cut.new({input}, {_pid})".replace("{input}", input).replace("{_pid}", __parse_identifier[rule])
# fn __parse_next_identifier[input: StringLiteral, rule: StringLiteral]() -> String:
#     return "RuleVariant.Next.new({input}, {_pid})".replace("{input}", input).replace("{_pid}", __parse_identifier[rule]())
# fn __parse_next_identifier[input: StringLiteral]() -> String:
#     return String(input)


# fn __parse_operators[*, input: StringLiteral, plus: () = (), rule: List[StaticString]]() -> String:
#     return __parse_next_identifier["RuleVariant.Multiple.new({input})".replace("{input}", input), rule]()
# fn __parse_operators[*, input: StringLiteral, asterisc: () = (), rule: List[StaticString]]() -> String:
#     return __parse_next_identifier["RuleVariant.Maybe.new(RuleVariant.Multiple.new({input}))".replace("{input}", input), rule]()
# fn __parse_operators[*, input: StringLiteral, maybe: () = (), rule: List[StaticString]]() -> String:
#     return __parse_next_identifier["RuleVariant.Maybe.new({input})".replace("{input}", input), rule]()
# fn __parse_operators[*, separator: StringLiteral, label: StringLiteral, rule: List[StaticString]]() -> String:
#     return __parse_next_identifier["RuleVariant.Next.new({_pid1},RuleVariant.Maybe.new(RuleVariant.Multiple.new(RuleVariant.Next.new({separator}, {_pid2}))))".replace("{separator}", separator).replace("{_pid1}", __parse_identifier[label]()).replace("{_pid2}", __parse_identifier[label]()), rule]()

# fn __parse_identifier[*, negative: ()= (), lookahead: StringLiteral, rule: List[StaticString]]() -> String:
#     return __parse_next_identifier["RuleVariant.NegativeLookahead.new({_pid})".replace("{_pid}", __parse_identifier[lookahead]()), rule]()

# fn __parse_identifier[*, positive: ()= (), lookahead: StringLiteral, rule: List[StaticString]]() -> String:
#     return __parse_next_identifier["RuleVariant.PositiveLookahead.new({_pid})".replace("{_pid}", __parse_identifier[lookahead]()), rule]()

# fn __parse_identifier[*, name: StringLiteral, rule: List[StaticString]]() -> String:
#     return __parse_operators["RuleVariant.Identifier.new({name})".replace("{name}", name), rule]()

# fn __parse_identifier[*, string: StringLiteral, rule: List[StaticString]]() -> String:
#     return __parse_operators["RuleVariant.Keyword.new({string})".replace("{string}", string), rule]()

# fn __parse_identifier[*, group: ()=(),  inner: StringLiteral, rule: List[StaticString]]() -> String:
#     return __parse_operators[__parse_or[[], inner], rule]()

# fn __parse_identifier[*, optional: () = (), inner: StringLiteral, rule: List[StaticString]]() -> String:
#     return __parse_operators["RuleVariant.Maybe.new({_por})".replace("{_por}", __parse_or([], inner)), rule]()


# fn __parse_or[saved: StringLiteral, or: () = (), rule: StringLiteral]() -> String:
#     return StaticString("RuleVariant.Or.new({_pid}, {_por})").replace("{_pid}", __parse_identifier[saved]()).replace("{_por}", __parse_or["", rule]())
# fn __parse_or[saved: StringLiteral, next: StringLiteral, rule: StringLiteral]() -> String:
#     alias new_saved = StringSlice(saved).write(" ", next)
#     return __parse_or[new_saved, rule]()
# fn __parse_or[saved: StringLiteral]() -> String:
#     return __parse_identifier(saved)

# fn __parse_at[*, error_recovery: Bool = False, rule: StringLiteral]() -> String:
#     @parameter
#     if error_recovery:
#         return StaticString("RuleVariant.DoesErrorRecovery.new({__parse_or})").replace(
#             "{__parse_or}", __parse_or(rule)
#         )
#     else:
#         return __parse_or({}, rule)


# fn __parse_reduce[
#     *, may_be_ommited: Bool = False, rule: StringLiteral
# ]() -> String:
#     @parameter
#     if may_be_ommited:
#         return StaticString("RuleVariant.NodeMayBeOmmited.new({_pr})").replace(
#             "{_pr}", __parse_at[rule]()
#         )

#     else:
#         return __parse_at[rule]()


fn __parse_rules[
    NonterminalType: StringLiteral,
    rules: StringLiteral,
    label: StringLiteral,
    union: __type_of("|"),
    rule0: StaticString,
    rule: List[StaticString],
    *,
]() -> String:
    return __parse_rule[NonterminalType, rules, [label], rule0, rule]()


fn __parse_rules[
    NonterminalType: StringLiteral,
    rules: StringLiteral,
    label: StringLiteral,
    colons: __type_of(":"),
    rule0: StaticString,
    rule: List[StaticString],
]() -> String:
    return __parse_rule[NonterminalType, rules, [label], rule0, rule]()


fn __parse_rule[
    NonterminalType: StringLiteral,
    rules: StringLiteral,
    saved0: StaticString,
    saved: List[StaticString],
    next: StringLiteral,
    rule0: StaticString,
    rule: List[StaticString],
]() -> String:
    r1 = __parse_rule[NonterminalType, rules, saved]()
    r2 = __parse_rule[NonterminalType, rules, next, rule]
    return String(r1, r2)


fn __parse_rule[
    NonterminalType: StringLiteral,
    rules: StringLiteral,
    saved: LiteralString,
    next: StringLiteral,
    rule: List[StaticString],
]() -> String:
    return __parse_rule[NonterminalType, rules, saved + next, rule]()


fn __parse_rule[
    NonterminalType: StringLiteral,
    rules: StringLiteral,
    label: StringLiteral,
    saved: StringLiteral,
]() -> String:
    alias _parse_reduce = __parse_reduce[saved]()
    StaticString(
        """
        var key = InternalNonterminalType(Int({NonterminalType}.{label}))
        if key in {rules}:
            os.abort("Key exists twice: `{label}`")

        rules.insert(key, ({label}, {__parse_reduce}))
    """
    ).replace("{NonterminalType}", NonterminalType).replace(
        "{rules}", rules
    ).replace(
        "{label}", label
    ).replace(
        "{__parse_reduce}", _parse_reduce
    )


fn __parse_soft_keywords[
    TerminalType: StringLiteral, soft_keywords: List[StaticString]
]() -> String:
    alias kwds_len = len(soft_keywords)
    var buff = String(
        "var soft_keywords = Dict[InternalTerminalType,"
        " Set[StaticString]](capacity={len})"
    ).replace("{len}", String(kwds_len))

    @parameter
    for keyword in soft_keywords:
        kwds = keyword.split(":")
        terminal, string = kwds[0], kwds[1]
        buff.write(
            String(
                """
        soft_keywords[InternalTerminalType(Int({TerminalType}.{terminal}))] = {string}
        """
            )
            .replace("{len}", String(kwds_len))
            .replace("{TerminalType}", TerminalType)
            .replace("{terminal}", terminal)
            .replace("{string}", string)
        )

    return buff^


fn __create_node[
    Tree: StringLiteral,
    Node: StringLiteral,
    NodeType: StringLiteral,
    NonterminalType: StringLiteral,
    TerminalType: StringLiteral,
    first_node: StringLiteral,
    rules_to_nodes: List[StaticString],
]() -> String:
    return {}


fn test_empty_rule[write_to: Path = "test_empty_rule.mojo"]() raises:
    var grammar_file = create_grammar[
        "GRAMMAR",
        "TestGrammar",
        "TestTree",
        "TestNode",
        "TestNodeType",
        "TestNonterminalType",
        "TestTokenizer",
        "TestTerminal",
        "TestTerminalType",
        soft_keywords= [],
        first_node="rule1: rule2 | Foo",
        rules= ["rule2: Bar?"],
    ]()
    write_to.write_text(grammar_file)
