alias lit[l: IntLiteral] = __type_of(l).value


@fieldwise_init
@register_passable("trivial")
struct RuleVariant[_v: __mlir_type[`!pop.int_literal`] = lit[-1]]:
    alias Invalid = RuleVariant[]()

    alias Identifier = RuleVariant[lit[0]]()
    alias Keyword = RuleVariant[lit[1]]()
    alias Or = RuleVariant[lit[2]]()
    alias Cut = RuleVariant[lit[3]]()
    alias Maybe = RuleVariant[lit[4]]()
    alias Multiple = RuleVariant[lit[5]]()
    alias NegativeLookahead = RuleVariant[lit[6]]()
    alias PositiveLookahead = RuleVariant[lit[7]]()
    alias Next = RuleVariant[lit[8]]()
    alias NodeMayBeOmmited = RuleVariant[lit[9]]()
    alias DoesErrorRecovery = RuleVariant[lit[10]]()
    alias value = IntLiteral[_v]()

    fn matches(self, other: Rule) -> Bool:
        return self.value == other.variant

    fn new(var self: __type_of(Self.Identifier), string: StaticString) -> Rule:
        return Rule(self.value, {{}, {}, string})

    fn new(var self: __type_of(Self.Keyword), string: StaticString) -> Rule:
        return Rule(self.value, {{}, {}, string})

    fn new(
        var self: __type_of(Self.Or),
        r1: Rule,
        r2: Rule,
    ) -> Rule:
        return Rule(
            self.value, {UnsafePointer(to=r1), UnsafePointer(to=r2), {}}
        )

    fn new(
        var self: __type_of(Self.Cut),
        r1: Rule,
        r2: Rule,
    ) -> Rule:
        return Rule(
            self.value, {UnsafePointer(to=r1), UnsafePointer(to=r2), {}}
        )

    fn new(var self: __type_of(Self.Next), r1: Rule, r2: Rule) -> Rule:
        return Rule(
            self.value, {UnsafePointer(to=r1), UnsafePointer(to=r2), {}}
        )

    fn new(var self: __type_of(Self.Maybe), r1: Rule) -> Rule:
        return Rule(self.value, {UnsafePointer(to=r1), {}, {}})

    fn new(var self: __type_of(Self.Multiple), r1: Rule) -> Rule:
        return Rule(self.value, {UnsafePointer(to=r1), {}, {}})

    fn new(var self: __type_of(Self.NegativeLookahead), r1: Rule) -> Rule:
        return Rule(self.value, {UnsafePointer(to=r1), {}, {}})

    fn new(var self: __type_of(Self.PositiveLookahead), r1: Rule) -> Rule:
        return Rule(self.value, {UnsafePointer(to=r1), {}, {}})

    fn new(var self: __type_of(Self.NodeMayBeOmmited), r1: Rule) -> Rule:
        return Rule(self.value, {UnsafePointer(to=r1), {}, {}})

    fn new(var self: __type_of(Self.DoesErrorRecovery), r1: Rule) -> Rule:
        return Rule(self.value, {UnsafePointer(to=r1), {}, {}})

    fn __getitem__(
        var self: __type_of(Self.Identifier), rule: Rule
    ) -> StaticString:
        return rule.inner[2]

    fn __getitem__(
        var self: __type_of(Self.Keyword), rule: Rule
    ) -> StaticString:
        return rule.inner[2]

    fn __getitem__(
        var self: __type_of(Self.Or), rule: Rule
    ) -> Tuple[UnsafePointer[Rule], UnsafePointer[Rule]]:
        return (rule.inner[0], rule.inner[1])

    fn __getitem__(
        var self: __type_of(Self.Cut), rule: Rule
    ) -> Tuple[UnsafePointer[Rule], UnsafePointer[Rule]]:
        return (rule.inner[0], rule.inner[1])

    fn __getitem__(
        var self: __type_of(Self.Next), rule: Rule
    ) -> Tuple[UnsafePointer[Rule], UnsafePointer[Rule]]:
        return (rule.inner[0], rule.inner[1])

    fn __getitem__(
        var self: __type_of(Self.Maybe), rule: Rule
    ) -> ref [rule.inner[0].origin] Rule:
        return rule.inner[0][]

    fn __getitem__(
        var self: __type_of(Self.Multiple), rule: Rule
    ) -> ref [rule.inner[0].origin] Rule:
        return rule.inner[0][]

    fn __getitem__(
        var self: __type_of(Self.NegativeLookahead), rule: Rule
    ) -> ref [rule.inner[0].origin] Rule:
        return rule.inner[0][]

    fn __getitem__(
        var self: __type_of(Self.PositiveLookahead), rule: Rule
    ) -> ref [rule.inner[0].origin] Rule:
        return rule.inner[0][]

    fn __getitem__(
        var self: __type_of(Self.NodeMayBeOmmited), rule: Rule
    ) -> ref [rule.inner[0].origin] Rule:
        return rule.inner[0][]

    fn __getitem__(
        var self: __type_of(Self.DoesErrorRecovery), rule: Rule
    ) -> ref [rule.inner[0].origin] Rule:
        return rule.inner[0][]


@fieldwise_init
struct Rule(Copyable, Movable, Writable):
    var variant: Int
    var inner: (UnsafePointer[Rule], UnsafePointer[Rule], StaticString)

    fn write_to(self, mut w: Some[Writer]):
        w.write("Rule(categ:", self.variant, ")")
