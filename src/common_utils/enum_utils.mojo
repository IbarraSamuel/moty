alias lit[i: IntLiteral] = __type_of(i).value


trait ComptimeEnum:
    alias Runtime: RuntimeEnum
    alias lit_value: __mlir_type[`!pop.int_literal`]


trait RuntimeEnum:
    @always_inline("nodebug")
    fn get_variant(self) -> Int:
        ...


fn matches[comptime: ComptimeEnum, /](runtime: comptime.Runtime) -> Bool:
    return IntLiteral[comptime.lit_value]() == runtime.get_variant()
