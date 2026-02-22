import std/unittest

import nimp

suite "hobby builder":
  test "create open path":
    let path = nullpath().knot(p(1, 1)).curve().knot(p(2, 2)).curve().knot(p(3, 1)).finish()
    check path.n == 3
    check not path.isCycle

  test "asString snapshots":
    let openPath = nullpath().knot(p(1, 1)).curve().knot(p(2, 2)).curve().knot(p(3, 1)).finish()
    check asString(openPath) == "(1,1) .. (2,2) .. (3,1)"

    let cyclePath =
      nullpath().knot(p(1, 1)).curve().knot(p(2, 2)).curve().knot(p(3, 1)).curve().knot(
        p(2, 0)
      ).curve().cycle()
    check asString(cyclePath) == "(1,1) .. (2,2) .. (3,1) .. (2,0) .. cycle"

  test "dir and tension settings":
    let path = nullpath().dirKnot(p(1, 1), p(1, 0)).curve().knot(p(2, 1)).finish()
    check abs(path.postDir(0).x - 1.0) < 1.0e-12
    check abs(path.postDir(0).y - 0.0) < 1.0e-12

    var p2 = nullpath().knot(p(1, 1)).tensionCurve(0.1, 10.0).finish()
    check abs(p2.postTension(0) - 0.75) < 1.0e-12
    check abs(p2.preTension(1) - 4.0) < 1.0e-12

  test "controls container":
    let c = newControls()
    c.setPostControl(0, p(1.0, 2.0))
    c.setPreControl(1, p(3.0, 4.0))
    check abs(c.postControl(0).x - 1.0) < 1.0e-12
    check abs(c.preControl(1).y - 4.0) < 1.0e-12

  test "empty path join errors":
    expect(ValueError):
      discard nullpath().line()
    expect(ValueError):
      discard nullpath().curve()
    expect(ValueError):
      discard nullpath().tensionCurve(1.2, 0.9)
