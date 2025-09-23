from common_utils.enum_utils import lit, ComptimeEnum, RuntimeEnum


@fieldwise_init
@register_passable("trivial")
struct ModeDataVariant[_v: __mlir_type[`!pop.int_literal`] = lit[-1]]:
    alias Alternative = ModeDataVariant[lit[0]]()
    alias LL = ModeDataVariant[lit[1]]()

    alias value = IntLiteral[_v]()

    fn matches(self, runtime: ModeData) -> Bool:
        return self.value == runtime.variant

    fn new[
        fallback_plan_o: ImmutableOrigin
    ](var self: __type_of(Self.LL)) -> ModeData[fallback_plan_o]:
        return {self.value, {}}

    fn new[
        fallback_plan_o: ImmutableOrigin
    ](
        var self: __type_of(Self.Alternative),
        var data_tracking_point: BacktrackingPoint[fallback_plan_o],
    ) -> ModeData[fallback_plan_o]:
        return ModeData(self.value, data_tracking_point^)

    fn __getitem__(
        var self: __type_of(Self.Alternative), mode_data: ModeData
    ) -> ref [mode_data.inner._value] BacktrackingPoint[
        mode_data.fallback_plan_o
    ]:
        return mode_data.inner.value()


@fieldwise_init
struct ModeData[fallback_plan_o: ImmutableOrigin](Copyable, Movable):
    var variant: Int
    var inner: Optional[BacktrackingPoint[fallback_plan_o]]
