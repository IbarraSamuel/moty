# from collections import Set
from sys.intrinsics import _type_is_eq
from os import abort


@fieldwise_init
@register_passable("trivial")
struct RuleVariant(EqualityComparable):
    alias Invalid = -1

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

    @always_inline("nodebug")
    fn __eq__(self, other: Self) -> Bool:
        return self._v == other._v

    fn __call__(
        var self,
        *,
        r1: UnsafePointer[Rule] = {},
        r2: UnsafePointer[Rule] = {},
        s: StaticString = {},
    ) -> Rule:
        if not (
            (self == Self.Identifier and s != {})
            or (self == Self.Keyword and s != {})
            or (self == Self.Or and r1 != {} and r2 != {})
            or (self == Self.Cut and r1 != {} and r2 != {})
            or (self == Self.Maybe and r1 != {})
            or (self == Self.Multiple and r1 != {})
            or (self == Self.NegativeLookahead and r1 != {})
            or (self == Self.PositiveLookahead and r1 != {})
            or (self == Self.Next and r1 != {} and r2 != {})
            or (self == Self.NodeMayBeOmmited and r1 != {})
            or (self == Self.DoesErrorRecovery and r1 != {})
        ):
            abort("Error on Rule creation.")

        return Rule(self, (r1, r2, s))


@fieldwise_init
struct Rule(Copyable, Movable, Writable):
    var variant: RuleVariant
    var _content: (UnsafePointer[Rule], UnsafePointer[Rule], StaticString)

    fn write_to(self, mut w: Some[Writer]):
        w.write("Rule(categ:", self.variant._v, ")")

    # @implicit
    # fn __init__(out self, variant: RuleVariant = RuleVariant.Invalid):
    #     self._content = ({}, {}, {})
    #     self.variant = variant

    @always_inline("nodebug")
    fn matches(self, other: RuleVariant) -> Bool:
        return self.variant == other

    fn get[t: Copyable](self) -> t:
        if (
            self.matches(RuleVariant.Identifier)
            or self.matches(RuleVariant.Keyword)
        ) and _type_is_eq[t, StaticString]():
            return rebind[t](self._content[2]).copy()

        if (
            self.matches(RuleVariant.Or)
            or self.matches(RuleVariant.Cut)
            or self.matches(RuleVariant.Next)
        ) and _type_is_eq[t, Tuple[Rule, Rule]]():
            return rebind[t]((self._content[0], self._content[1])).copy()

        if (
            self.matches(RuleVariant.Maybe)
            or self.matches(RuleVariant.Multiple)
            or self.matches(RuleVariant.NegativeLookahead)
            or self.matches(RuleVariant.PositiveLookahead)
            or self.matches(RuleVariant.NodeMayBeOmmited)
            or self.matches(RuleVariant.DoesErrorRecovery)
        ) and _type_is_eq[t, Rule]():
            return rebind[t](self._content[0]).copy()

        abort("Failed to get value, due to type specified in the getter.")

        # NOTE: This never runs
        return rebind[t](self._content).copy()
