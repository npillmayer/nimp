import std/unittest
import nimp

suite "pair":
  test "constructor and accessors":
    let pt = p(3.5, -2.0)
    check pt.x == 3.5
    check pt.y == -2.0

  test "float predicates":
    check isZero(1.0e-8)
    check isOne(1.0 + 1.0e-8)

  test "zap pair":
    let pt = p(1.0e-8, -1.0e-8).zap
    check pt.x == 0.0
    check pt.y == 0.0

  test "pair equality":
    check equal(p(1.0, 2.0), p(1.0 + 1.0e-8, 2.0 - 1.0e-8))
