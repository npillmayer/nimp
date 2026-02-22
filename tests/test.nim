## Package-level tests.

import std/unittest
import nimp

suite "nimp package":
  test "nimp imports":
    let z = p(0.0, 0.0)
    check z.x == 0.0
    check z.y == 0.0
