## 2D numeric primitives mirroring arithm.Pair from Go.

import std/[complex, math]

const Epsilon* = 1.0e-7

# Pair is represented as a complex number: re=x, im=y.
type Pair* = Complex64

proc p*(x, y: float64): Pair {.inline.} =
  complex64(x, y)

proc x*(pt: Pair): float64 {.inline.} =
  pt.re

proc y*(pt: Pair): float64 {.inline.} =
  pt.im

proc isZero*(v: float64): bool {.inline.} =
  abs(v) <= Epsilon

proc isOne*(v: float64): bool {.inline.} =
  abs(1.0 - v) <= Epsilon

proc zap*(v: float64): float64 {.inline.} =
  if isZero(v): 0.0 else: v

proc rounded*(v: float64): float64 {.inline.} =
  round(v / Epsilon) * Epsilon

proc zap*(pt: Pair): Pair {.inline.} =
  p(zap(pt.x), zap(pt.y))

proc equal*(a, b: Pair): bool {.inline.} =
  isZero(a.x - b.x) and isZero(a.y - b.y)
