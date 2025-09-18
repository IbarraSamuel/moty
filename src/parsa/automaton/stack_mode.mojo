@fieldwise_init
@register_passable("trivial")
struct StackModeVariant(EqualityComparable):
    alias Invalid = Self(-1)
    alias Alternative = Self(0)
    alias LL = Self(1)

    var _v: Int

    fn __eq__(self, other: Self) -> Bool:
        return self._v == other._v

    fn __call__[
        dfa_origin: ImmutableOrigin
    ](
        self,
        plan: UnsafePointer[Plan[dfa_origin], mut=False] = {},
    ) -> StackMode[dfa_origin]:
        new_self = Self(self._v)
        if self == Self.Alternative and plan != {}:
            new_self.inner = plan
        elif self == Self.LL:
            pass
        else:
            abort("Invalid StackMode")
        return new_self^


@fieldwise_init
struct StackMode[dfa_origin: ImmutableOrigin](
    Copyable, EqualityComparable, Identifiable, Movable, Writable
):
    var variant: StackModeVariant
    var inner: UnsafePointer[Plan[dfa_origin], mut=False]

    fn __eq__(self, other: Self) -> Bool:
        var inner_is_eq = (
            self.inner and other.inner and self.inner == other.inner
        ) or not (self.inner or other.inner)

        return self.variant == other.variant and inner_is_eq

    fn matches(self, other: StackModeVariant) -> Bool:
        return self.variant == other

    fn get(self) -> ref [StaticConstantOrigin] Plan[dfa_origin]:
        if self is materialize[Self.Alternative]():
            return self.inner[]

        abort("Invalid getter for StackMode")
        return self.inner[]

    fn write_to(self, mut w: Some[Writer]):
        if self.matches(Self.Alternative):
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
