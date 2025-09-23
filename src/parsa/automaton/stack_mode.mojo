alias lit[i: IntLiteral] = __type_of(i).value


@fieldwise_init
@register_passable("trivial")
struct StackModeVariant[_v: __mlir_type[`!pop.int_literal`] = lit[-1]]:
    alias Invalid = StackModeVariant[]()
    alias Alternative = StackModeVariant[lit[0]]()
    alias LL = StackModeVariant[lit[1]]()

    alias value = IntLiteral[_v]()

    fn matches(self, stack_mode: StackMode) -> Bool:
        return self.value == stack_mode.variant

    fn new(
        var self: __type_of(Self.Alternative),
        ref plan: Plan,
    ) -> StackMode:
        return {self.value, UnsafePointer(to=plan)}

    fn new(var self: __type_of(Self.LL)) -> StackMode:
        return {self.value, {}}

    fn __getitem__(
        var self: __type_of(Self.Alternative), ref stack_mode: StackMode
    ) -> UnsafePointer[Plan, mut=False]:
        return stack_mode.inner


@fieldwise_init
struct StackMode(Copyable, EqualityComparable, Movable, Writable):
    var variant: Int
    var inner: UnsafePointer[Plan, mut=False]

    fn __eq__(self, other: Self) -> Bool:
        var inner_is_eq = (
            self.inner and other.inner and self.inner == other.inner
        ) or not (self.inner or other.inner)

        return self.variant == other.variant and inner_is_eq

    fn write_to(self, mut w: Some[Writer]):
        if StackModeVariant.Alternative.matches(self):
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
