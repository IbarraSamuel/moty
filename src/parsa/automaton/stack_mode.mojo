from parsa.automaton import Plan


@fieldwise_init
@register_passable("trivial")
struct StackModeVariant[
    _v: __mlir_type[`!pop.int_literal`] = __type_of(-1).value
](EqualityComparable):
    alias Invalid = StackModeVariant[]()
    alias Alternative = StackModeVariant[__type_of(0).value]()
    alias LL = StackModeVariant[__type_of(1).value]()

    alias value = IntLiteral[_v]()

    @always_inline("builtin")
    fn __eq__(self, other: Self) -> Bool:
        return True

    @always_inline("builtin")
    fn __eq__(self, other: StackModeVariant[_]) -> Bool:
        return self.value == other.value

    fn matches(self, stack_mode: StackMode) -> Bool:
        return self.value == stack_mode.variant

    fn new[
        dfa_origin: ImmutableOrigin
    ](
        var self: __type_of(Self.Alternative),
        ref [ImmutableAnyOrigin]plan: Plan[dfa_origin],
    ) -> StackMode[dfa_origin]:
        return {self.value, Pointer(to=plan)}

    fn new[
        dfa_origin: ImmutableOrigin
    ](var self: __type_of(Self.LL)) -> StackMode[dfa_origin]:
        return {self.value, None}

    fn __getitem__(
        var self: __type_of(Self.Alternative), ref stack_mode: StackMode
    ) -> ref [stack_mode.inner._value] Pointer[
        Plan[stack_mode.dfa_origin], ImmutableAnyOrigin
    ]:
        return stack_mode.inner.value()


@fieldwise_init
struct StackMode[dfa_origin: ImmutableOrigin](
    Copyable, EqualityComparable, Movable, Writable
):
    var variant: Int
    var inner: Optional[Pointer[Plan[dfa_origin], ImmutableAnyOrigin]]

    fn __eq__(self, other: Self) -> Bool:
        var inner_is_eq = (
            self.inner
            and other.inner
            and self.inner.value() == other.inner.value()
        ) or not (self.inner or other.inner)

        return self.variant == other.variant and inner_is_eq

    fn write_to(self, mut w: Some[Writer]):
        if StackModeVariant.Alternative.matches(self):
            ref dfa = self.inner.value()[].next_dfa()
            w.write(
                "Alternative(",
                dfa.from_rule,
                " #",
                dfa.list_index.inner,
                ")",
            )
        else:
            w.write("LL")


# @fieldwise_init
# struct StackMode[dfa_origin: ImmutableOrigin](
#     Copyable, EqualityComparable, Identifiable, Movable, Writable
# ):
#     var variant: StackModeVariant
#     var inner: UnsafePointer[Plan[dfa_origin], mut=False]

#     fn __eq__(self, other: Self) -> Bool:
#         var inner_is_eq = (
#             self.inner and other.inner and self.inner == other.inner
#         ) or not (self.inner or other.inner)

#         return self.variant == other.variant and inner_is_eq

#     fn matches(self, other: StackModeVariant) -> Bool:
#         return self.variant == other

#     fn get(self) -> ref [StaticConstantOrigin] Plan[dfa_origin]:
#         if self is materialize[Self.Alternative]():
#             return self.inner[]

#         abort("Invalid getter for StackMode")
#         return self.inner[]

#     fn write_to(self, mut w: Some[Writer]):
#         if self.matches(Self.Alternative):
#             ref dfa = self.inner[].next_dfa()
#             w.write(
#                 "Alternative(",
#                 dfa.from_rule,
#                 " #",
#                 dfa.list_index.inner,
#                 ")",
#             )
#         else:
#             w.write("LL")
