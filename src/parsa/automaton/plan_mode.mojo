alias lit[l: IntLiteral] = __type_of(l).value


@fieldwise_init
@register_passable("trivial")
struct PlanModeVariant[_v: __mlir_type[`!pop.int_literal`] = lit[-1]]:
    alias Invalid = PlanModeVariant[]()
    alias LeftRecursive = PlanModeVariant[lit[0]]()
    alias LL = PlanModeVariant[lit[1]]()
    alias PositivePeek = PlanModeVariant[lit[2]]()

    alias value = IntLiteral[_v]()

    fn matches(self, plan_mode: PlanMode) -> Bool:
        return self.value == plan_mode.variant

    fn new(var self) -> PlanMode:
        return PlanMode(self.value)


@fieldwise_init
@register_passable("trivial")
struct PlanMode(Writable):
    var variant: Int

    fn write_to(self, mut w: Some[Writer]):
        w.write("PlanMode(", self.variant, ")")
