# from collections import Set
from sys.intrinsics import _type_is_eq
from os import abort


struct Rule(Identifiable, ImplicitlyCopyable, Movable, Writable):
    alias Invalid = Self()

    alias Identifier = Self(0)
    alias Keyword = Self(1)
    alias Or = Self(2)
    alias Cut = Self(3)
    alias Maybe = Self(4)
    alias Multiple = Self(5)
    alias NegativeLookahead = Self(6)
    alias PositiveLookahead = Self(7)
    alias Next = Self(8)
    alias NodeMayBeOmmited = Self(9)
    alias DoesErrorRecovery = Self(10)
    var _v: Int

    var _content: (UnsafePointer[Rule], UnsafePointer[Rule], StaticString)

    fn write_to(self, mut w: Some[Writer]):
        w.write("Rule(categ:", self._v, ")")

    fn __init__(out self, category: Int = -1):
        self._content = ({}, {}, {})
        if not (0 <= category <= 10):
            self._v = -1
            return

        self._v = category

    fn __is__(self, other: Self) -> Bool:
        return self._v == other._v

    fn __call__(
        self,
        *,
        r1: UnsafePointer[Rule] = {},
        r2: UnsafePointer[Rule] = {},
        s: StaticString = {},
    ) -> Self:
        if not (
            (self is Self.Identifier and s != {})
            or (self is Self.Keyword and s != {})
            or (self is Self.Or and r1 != {} and r2 != {})
            or (self is Self.Cut and r1 != {} and r2 != {})
            or (self is Self.Maybe and r1 != {})
            or (self is Self.Multiple and r1 != {})
            or (self is Self.NegativeLookahead and r1 != {})
            or (self is Self.PositiveLookahead and r1 != {})
            or (self is Self.Next and r1 != {} and r2 != {})
            or (self is Self.NodeMayBeOmmited and r1 != {})
            or (self is Self.DoesErrorRecovery and r1 != {})
        ):
            abort("Error on Rule creation.")

        new_self = Self(self._v)
        new_self._content = (r1, r2, s)
        return new_self^

    fn get[t: Copyable](self) -> t:
        if (self is Self.Identifier or self is Self.Keyword) and _type_is_eq[
            t, StaticString
        ]():
            return rebind[t](self._content[2]).copy()

        if (
            self is Self.Or or self is Self.Cut or self is Self.Next
        ) and _type_is_eq[t, Tuple[Rule, Rule]]():
            return rebind[t]((self._content[0], self._content[1])).copy()

        if (
            self is Self.Maybe
            or self is Self.Multiple
            or self is Self.NegativeLookahead
            or self is Self.PositiveLookahead
            or self is Self.NodeMayBeOmmited
            or self is Self.DoesErrorRecovery
        ) and _type_is_eq[t, Rule]():
            return rebind[t](self._content[0]).copy()

        abort("Failed to get value, due to type specified in the getter.")

        # NOTE: This never runs
        return rebind[t](self._content).copy()


# alias str = __mlir_type[`!kgen.string`]
# alias strof[v: StringLiteral] = __type_of(v).value
# alias INV = strof["Invalid"]


# struct Rule[
#     v: str = INV,
#     r1: str = INV,
#     r2: str = INV,
# ](Identifiable):
#     alias InvalidType = Rule[]

#     alias IdentifierType = Rule[strof["Identifier"]]
#     alias KeywordType = Rule[strof["Keyword"]]
#     alias OrType[r1: str = INV, r2: str = INV] = Rule[strof["Or"], r1, r2]
#     alias CutType[r1: str = INV, r2: str = INV] = Rule[strof["Cut"], r1, r2]
#     alias MaybeType[r1: str = INV] = Rule[strof["Maybe"], r1]
#     alias MultipleType[r1: str = INV] = Rule[strof["Multiple"], r1]
#     alias NegativeLookaheadType[r1: str = INV] = Rule[
#         strof["NegativeLookahead"], r1
#     ]
#     alias PositiveLookaheadType[r1: str = INV] = Rule[
#         strof["PositiveLookahead"], r1
#     ]
#     alias NextType[r1: str = INV, r2: str = INV] = Rule[strof["Next"], r1, r2]
#     alias NodeMayBeOmmitedType[r1: str = INV] = Rule[
#         strof["NodeMayBeOmmited"], r1
#     ]
#     alias DoesErrorRecoveryType[r1: str = INV] = Rule[
#         strof["DoesErrorRecovery"], r1
#     ]

#     alias Invalid = Self.InvalidType()

#     alias Identifier = Self.IdentifierType()
#     alias Keyword = Self.KeywordType()
#     alias Or = Self.OrType[]()
#     alias Cut = Self.CutType[]()
#     alias Maybe = Self.MaybeType[]()
#     alias Multiple = Self.MultipleType[]()
#     alias NegativeLookahead = Self.NegativeLookaheadType[]()
#     alias PositiveLookahead = Self.PositiveLookaheadType[]()
#     alias Next = Self.NextType[]()
#     alias NodeMayBeOmmited = Self.NodeMayBeOmmitedType[]()
#     alias DoesErrorRecovery = Self.DoesErrorRecoveryType[]()

#     var rules: (
#         UnsafePointer[Rule[r1]],
#         UnsafePointer[Rule[r2]],
#         StaticString,
#     )

#     fn __init__(
#         out self,
#         var v1: UnsafePointer[Rule[r1]] = {},
#         var v2: UnsafePointer[Rule[r2]] = {},
#         var s: StaticString = {},
#     ):
#         self.rules = (v1, v2, s)

#     # Initializers

#     fn __call__(
#         var self: Self.IdentifierType, value: StaticString
#     ) -> Self.IdentifierType:
#         return {s = value}

#     fn __call__(
#         var self: Self.KeywordType, value: StaticString
#     ) -> Self.KeywordType:
#         return {s = value}

#     fn __call__(
#         var self: Self.OrType[], ref value_1: Rule[**_], ref value_2: Rule[**_]
#     ) -> Self.OrType[r1=value_1.v, r2=value_2.v]:
#         var p1 = UnsafePointer(to=value_1)
#         var p2 = UnsafePointer(to=value_2)
#         return {p1, p2}

#     fn __call__(
#         var self: Self.CutType, value_1: Rule, value_2: Rule
#     ) -> Self.CutType:
#         var p1 = UnsafePointer[mut=False, origin=ImmutableAnyOrigin](to=value_1)
#         var p2 = UnsafePointer[mut=False, origin=ImmutableAnyOrigin](to=value_2)
#         return {p1, p2}

#     fn __call__(var self: Self.MaybeType, value: Rule) -> Self.MaybeType:
#         var p1 = UnsafePointer[mut=False, origin=ImmutableAnyOrigin](to=value)
#         return {p1}

#     fn __call__(
#         var self: Self.MultipleType, value: StaticString
#     ) -> Self.MultipleType:
#         return {value}

#     fn __call__(
#         var self: Self.NegativeLookaheadType, value: StaticString
#     ) -> Self.NegativeLookaheadType:
#         return {value}

#     fn __call__(
#         var self: Self.PositiveLookaheadType, value: StaticString
#     ) -> Self.PositiveLookaheadType:
#         return {value}

#     fn __call__(
#         var self: Self.NextType, value_1: StaticString, value_2: StaticString
#     ) -> Self.NextType:
#         return {value_1, value_2}

#     fn __call__(
#         var self: Self.NodeMayBeOmmitedType, value: StaticString
#     ) -> Self.NodeMayBeOmmitedType:
#         return {value}

#     fn __call__(
#         var self: Self.DoesErrorRecoveryType, value: StaticString
#     ) -> Self.DoesErrorRecoveryType:
#         return {value}

#     # Identifier
#     fn __is__(self, other: Self) -> Bool:
#         return True

#     fn __is__(self, other: Rule) -> Bool:
#         return False

#     # Getters
#     fn __getitem__(
#         self: Self.IdentifierType,
#     ) -> ref [self.rules[0]] StaticString:
#         return self.rules[0]

#     fn __getitem__(self: Self.KeywordType) -> ref [self.rules[0]] StaticString:
#         return self.rules[0]

#     fn __getitem__(
#         self: Self.OrType,
#     ) -> ref [self.rules] (StaticString, StaticString):
#         return self.rules

#     fn __getitem__(
#         self: Self.CutType,
#     ) -> ref [self.rules] (StaticString, StaticString):
#         return self.rules

#     fn __getitem__(self: Self.MaybeType) -> ref [self.rules[0]] StaticString:
#         return self.rules[0]

#     fn __getitem__(self: Self.MultipleType) -> ref [self.rules[0]] StaticString:
#         return self.rules[0]

#     fn __getitem__(
#         self: Self.NegativeLookaheadType,
#     ) -> ref [self.rules[0]] StaticString:
#         return self.rules[0]

#     fn __getitem__(
#         self: Self.PositiveLookaheadType,
#     ) -> ref [self.rules[0]] StaticString:
#         return self.rules[0]

#     fn __getitem__(
#         self: Self.NextType,
#     ) -> ref [self.rules] (StaticString, StaticString):
#         return self.rules

#     fn __getitem__(
#         self: Self.NodeMayBeOmmitedType,
#     ) -> ref [self.rules[0]] StaticString:
#         return self.rules[0]

#     fn __getitem__(
#         self: Self.DoesErrorRecoveryType,
#     ) -> ref [self.rules[0]] StaticString:
#         return self.rules[0]
