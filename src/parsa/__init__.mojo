from pathlib import Path
from os import abort


# fn comptime_split_string[
#     str: String, split_at: String
# ]() -> Tuple[String, String]:
#     alias idx = str.find(split_at)
#     return (str[:idx], str[idx + 1 :])


fn comptime_extend_list[
    T: Copyable & Movable, //, lst: List[T], item: T
]() -> List[T]:
    new_lst = materialize[lst]()
    new_lst.append(materialize[item]())
    return new_lst^


fn comptime_list_replace[
    T: Copyable & Movable, //, lst: List[T], idx: Int, item: T
]() -> List[T]:
    new_lst = materialize[lst]()
    new_lst[idx] = materialize[item]()
    return new_lst^


fn find_bracket[
    rs: List[StaticString],
    open_bracket: StringLiteral,
    end_bracket: StringLiteral,
]() -> Int:
    var depth = 0
    alias rule_len = len(rs)

    @parameter
    for i in range(1, rule_len):
        alias r = rs[i]
        if open_bracket in r:
            depth += 1
        elif end_bracket in r:
            depth -= 1

        if r.endswith(end_bracket) and depth == 0:
            return i
    else:
        abort("end of brackets not found!")
    return 0


alias struct_Grammar = """
{__create_node}


struct {Grammar}:
    var internal_grammar: Grammar[{Token}]

    fn __init__(out self):
        var rules = Dict[]
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


fn __parse_next_identifier[
    input: StaticString, rule: List[StaticString]
]() -> String:
    @parameter
    if len(rule) > 0 and rule[0].startswith("~"):
        alias new_inp = rule[0].removeprefix("~")
        alias new_rules = comptime_list_replace[rule, 0, new_inp]()
        return (
            "RuleVariant.Cut.new({input}, {_pid})".as_string_slice()
            .replace("{input}", input)
            .replace("{_pid}", __parse_identifier[new_rules]())
        )

    elif len(rule) > 0:
        return (
            "RuleVariant.Next.new({input}, {_pid})".as_string_slice()
            .replace("{input}", input)
            .replace("{_pid}", __parse_identifier[rule]())
        )

    else:
        return input


# fn __parse_next_identifier[input: StringLiteral, neg: () = (), rule: StringLiteral]() -> String:
#     return "RuleVariant.Cut.new({input}, {_pid})".replace("{input}", input).replace("{_pid}", __parse_identifier[rule])
# fn __parse_next_identifier[input: StringLiteral, rule: StringLiteral]() -> String:
#     return "RuleVariant.Next.new({input}, {_pid})".replace("{input}", input).replace("{_pid}", __parse_identifier[rule]())
# fn __parse_next_identifier[input: StringLiteral]() -> String:
#     return String(input)


fn __parse_operators[input: StaticString, rule: List[StaticString]]() -> String:
    @parameter
    if len(rule) > 0 and rule[0].startswith("+"):
        alias new_rule = rule[1:] if rule[0] == "+" else comptime_list_replace[
            rule, 0, rule[0].removeprefix("+")
        ]()
        return __parse_next_identifier[
            "RuleVariant.Multiple.new({input})".as_string_slice().replace(
                "{input}", input
            ),
            new_rule,
        ]()
    elif len(rule) > 0 and rule[0].startswith("*"):
        alias new_rule = rule[1:] if rule[0] == "*" else comptime_list_replace[
            rule, 0, rule[0].removeprefix("*")
        ]()
        return __parse_next_identifier[
            "RuleVariant.Maybe.new(RuleVariant.Multiple.new({input}))".as_string_slice().replace(
                "{input}", input
            ),
            new_rule,
        ]()
    elif len(rule) > 0 and rule[0].startswith("?"):
        alias new_rule = rule[1:] if rule[0] == "?" else comptime_list_replace[
            rule, 0, rule[0].removeprefix("?")
        ]()
        return __parse_next_identifier[
            "RuleVariant.Maybe.new({input})".as_string_slice().replace(
                "{input}", input
            ),
            new_rule,
        ]()
    elif len(rule) > 0 and rule[0].startswith(".") and "+" in rule[0]:
        alias separator = input
        alias w_end = rule[0].find(".")
        alias label = rule[0][1:w_end]
        alias to_replace = rule[0][w_end:]
        alias new_rule = comptime_list_replace[rule, 0, to_replace]()
        alias pid = __parse_identifier[[label]]()
        return __parse_next_identifier[
            "RuleVariant.Next.new({_pid1},RuleVariant.Maybe.new(RuleVariant.Multiple.new(RuleVariant.Next.new({separator},"
            " {_pid2}))))".as_string_slice()
            .replace("{separator}", separator)
            .replace("{_pid1}", pid)
            .replace("{_pid2}", pid),
            new_rule,
        ]()
    else:
        return __parse_next_identifier[input, rule]()


fn __parse_identifier[rule: List[StaticString]]() -> String:
    @parameter
    if rule[0].startswith("!"):
        alias lookahead = rule[0].removeprefix("!")
        return __parse_next_identifier[
            "RuleVariant.NegativeLookahead.new({_pid})".as_string_slice().replace(
                "{_pid}", __parse_identifier[[lookahead]]()
            ),
            rule[1:],
        ]()
    elif rule[0].startswith("&"):
        alias lookahead = rule[0].removeprefix("&")
        return __parse_next_identifier[
            "RuleVariant.PositiveLookahead.new({_pid})".as_string_slice().replace(
                "{_pid}", __parse_identifier[[lookahead]]()
            ),
            rule[1:],
        ]()

    elif len(rule) > 0 and rule[0].startswith('"') and rule[0].endswith('"'):
        alias string = rule[0]
        return __parse_operators[
            "RuleVariant.Keyword.new({string})".as_string_slice().replace(
                "{string}", string
            ),
            rule[1:],
        ]()

    elif (
        len(rule) > 0
        and not rule[0].startswith("(")
        and not rule[0].startswith("[")
    ):
        alias name = rule[0]
        return __parse_operators[
            "RuleVariant.Identifier.new({name})".as_string_slice().replace(
                "{name}", name
            ),
            rule[1:],
        ]()

    elif len(rule) > 0 and rule[0].startswith("("):
        alias first_rule = rule[0].removeprefix("(")

        alias i = find_bracket[rule, "(", ")"]()
        alias last_rule = rule[i].removesuffix(")")
        alias rule1 = comptime_list_replace[rule, 0, first_rule]()
        alias rule2 = comptime_list_replace[rule1, i, last_rule]()

        alias inner = rule2[:i]
        alias other_rules = rule2[i + 1 :]

        return __parse_operators[__parse_or[[], inner](), other_rules]()

    elif len(rule) > 0 and rule[0].startswith("["):
        alias first_rule = rule[0].removeprefix("[")

        alias i = find_bracket[rule, "[", "]"]()
        alias last_rule = rule[i].removesuffix(")")
        alias rule1 = comptime_list_replace[rule, 0, first_rule]()
        alias rule2 = comptime_list_replace[rule1, i, last_rule]()

        alias inner = rule2[:i]
        alias other_rules = rule2[i + 1 :]

        return __parse_operators[
            "RuleVariant.Maybe.new({_por})".as_string_slice().replace(
                "{_por}", __parse_or[[], inner]()
            ),
            other_rules,
        ]()

    abort("Unreachable!")
    return ""


fn __parse_or[saved: List[StaticString], rule: List[StaticString]]() -> String:
    @parameter
    if len(rule) > 1 and rule[0] == "|":
        return (
            StaticString("RuleVariant.Or.new({_pid}, {_por})")
            .replace("{_pid}", __parse_identifier[saved]())
            .replace("{_por}", __parse_or[[], rule[1:]]())
        )
    elif len(rule) > 0:
        alias new_saved = comptime_extend_list[saved, rule[0]]()
        return __parse_or[new_saved, rule[1:]]()

    return __parse_identifier[saved]()


fn __parse_at[rule: List[StaticString]]() -> String:
    @parameter
    if rule[0] == "@error_recovery":
        return StaticString(
            "RuleVariant.DoesErrorRecovery.new({__parse_or})"
        ).replace("{__parse_or}", __parse_or[[], rule[1:]]())
    else:
        return __parse_or[[], rule]()


fn __parse_reduce[rule: List[StaticString]]() -> String:
    @parameter
    if rule[0] == "?":
        return StaticString("RuleVariant.NodeMayBeOmmited.new({_pr})").replace(
            "{_pr}", __parse_at[rule[1:]]()
        )
    else:
        return __parse_at[rule]()


fn __parse_rules[
    NonterminalType: StringLiteral,
    rules: StringLiteral,
    rule: List[StaticString],
    *,
]() -> String:
    @parameter
    if len(rule) > 0 and rule[0].endswith(":") and rule[1] == "|":
        return __parse_rule[
            NonterminalType, rules, [rule[0].removesuffix(":")], rule[2:]
        ]()
    elif len(rule) > 0 and rule[0].endswith(":"):
        return __parse_rule[
            NonterminalType, rules, [rule[0].removesuffix(":")], rule[1:]
        ]()

    abort("This should not happen!")
    return ""


fn __parse_rule[
    NonterminalType: StringLiteral,
    rules: StringLiteral,
    saved: List[StaticString],
    rule: List[StaticString],
]() -> String:
    @parameter
    if len(rule) > 1 and rule[0].endswith(":"):
        alias r1 = __parse_rule[NonterminalType, rules, saved, []]()
        alias r2 = __parse_rules[NonterminalType, rules, rule]()
        return String(r1, r2)
    elif len(rule) > 0:
        alias new_saved = comptime_extend_list[saved, rule[0]]()
        return __parse_rule[NonterminalType, rules, new_saved, rule[1:]]()
    elif len(rule) == 0:
        var label = materialize[saved[0]]()
        return (
            StaticString(
                """
            var key = InternalNonterminalType(Int({NonterminalType}.{label}))
            if key in {rules}:
                os.abort("Key exists twice: `{label}`")

            {rules}[key] = ('{label}', {__parse_reduce})
        """
            )
            .replace("{NonterminalType}", NonterminalType)
            .replace("{rules}", rules)
            .replace("{label}", label)
            .replace("{__parse_reduce}", __parse_reduce[saved[1:]]())
        )
    abort("Unreachable!")
    return ""


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
    first_node: StaticString,
    rules_to_nodes: List[StaticString],
]() -> String:
    return {}


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
    rule: StringLiteral,
]() -> String:
    alias rules = rule.split()

    alias str_grammar = (
        struct_Grammar.as_string_slice()
        .replace(
            "{__create_node}",
            __create_node[
                Tree,
                Node,
                NodeType,
                NonterminalType,
                TerminalType,
                rules[0],
                rules[1:],
            ](),
        )
        .replace("{grammar}", grammar)
        .replace("{Grammar}", Grammar)
        .replace("{Tree}", Tree)
        .replace("{Node}", Node)
        .replace("{NodeType}", NodeType)
        .replace("{NonterminalType}", NonterminalType)
        .replace("{Tokenizer}", Tokenizer)
        .replace("{Token}", Token)
        .replace("{TerminalType}", TerminalType)
        .replace(
            "{__parse_rules}",
            __parse_rules[NonterminalType, "rules", rules](),
        )
        .replace(
            "{__parse_soft_keywords}",
            __parse_soft_keywords[TerminalType, soft_keywords](),
        )
    )

    return str_grammar


fn test_empty_rule[write_to: Path = "test_empty_rule.mojo"]() raises:
    var grammar_file = create_grammar[
        grammar="GRAMMAR",
        Grammar="TestGrammar",
        Tree="TestTree",
        Node="TestNode",
        NodeType="TestNodeType",
        NonterminalType="TestNonterminalType",
        Tokenizer="TestTokenizer",
        Token="TestTerminal",
        TerminalType="TestTerminalType",
        soft_keywords= [],
        rule="""
        rule1: Foo
        rule2: Bar?
        """,
    ]()
    write_to.write_text(grammar_file)
