alias lit[l: IntLiteral] = __type_of(l).value


@fieldwise_init
@register_passable("trivial")
struct FirstPlanVariant[_v: __mlir_type[`!pop.int_literal`] = lit[-1]](
    EqualityComparable
):
    alias Invalid = FirstPlanVariant[]()
    alias Calculated = FirstPlanVariant[lit[0]]()
    alias Calculating = FirstPlanVariant[lit[1]]()

    alias value = IntLiteral[_v]()

    @always_inline("builtin")
    fn __eq__(self, other: Self) -> Bool:
        return True

    @always_inline("builtin")
    fn __eq__(self, other: FirstPlanVariant) -> Bool:
        return False

    fn matches(self, other: FirstPlan) -> Bool:
        return self.value == other.variant

    fn new[
        dfa_origin: ImmutableOrigin
    ](
        var self: __type_of(Self.Calculated),
        var plans: Dict[InternalSquashedType, Plan[dfa_origin]],
        is_left_recursive: Bool,
    ) -> FirstPlan[dfa_origin]:
        return {self.value, {plans^, is_left_recursive}}

    fn new[
        dfa_origin: ImmutableOrigin
    ](var self: __type_of(Self.Calculating)) -> FirstPlan[dfa_origin]:
        return {self.value, {{}, {}}}

    fn __getitem__(
        var self: __type_of(Self.Calculated), first_plan: FirstPlan
    ) -> ref [first_plan.inner] Tuple[
        Dict[InternalSquashedType, Plan[first_plan.dfa_origin]], Bool
    ]:
        return first_plan.inner


@fieldwise_init
struct FirstPlan[dfa_origin: ImmutableOrigin](Copyable, Movable):
    var variant: Int
    var inner: Tuple[Dict[InternalSquashedType, Plan[dfa_origin]], Bool]
