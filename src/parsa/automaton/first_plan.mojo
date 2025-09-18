@fieldwise_init
@register_passable("trivial")
struct FirstPlanVariant(EqualityComparable):
    alias Invalid = Self(-1)
    alias Calculated = Self(0)
    alias Calculating = Self(1)

    var _v: Int

    fn __eq__(self, other: Self) -> Bool:
        return self._v == other._v

    @always_inline("nodebug")
    fn __call__[
        dfa_origin: ImmutableOrigin
    ](
        var self,
        *,
        var plans: Dict[InternalSquashedType, Plan[dfa_origin]] = {},
        var is_left_recursive: Bool = {},
    ) -> FirstPlan[dfa_origin]:
        # new_self = (self._v)
        if (
            self == FirstPlanVariant.Calculated
            and len(plans) == 0
            and is_left_recursive != {}
        ):
            return FirstPlan(self, (plans^, is_left_recursive))

        elif self == Self.Calculating:
            return FirstPlan[dfa_origin](self, {{}, {}})

        abort("Failed to create first plan.")
        return FirstPlan(self, (plans^, is_left_recursive))


@fieldwise_init
struct FirstPlan[dfa_origin: ImmutableOrigin](Copyable, Movable):
    var variant: FirstPlanVariant
    var inner: Tuple[Dict[InternalSquashedType, Plan[dfa_origin]], Bool]

    fn matches(self, other: FirstPlanVariant) -> Bool:
        return self.variant == other

    fn get(
        self,
    ) -> ref [self.inner] (Dict[InternalSquashedType, Plan[dfa_origin]], Bool,):
        if not (self.variant == FirstPlanVariant.Calculated):
            abort("Invalid getter for FirstPlan.Calculated.")
        return self.inner
