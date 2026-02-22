import std/[tables, unittest]

import nimp

suite "integration lineq+hobby":
  test "lineq-solved knot feeds hobby controls":
    var solved = initTable[int, float64]()
    let vr = VariableResolver(
      getVariableName: proc(n: int): string = "x." & $n,
      setVariableSolved: proc(n: int, v: float64) = solved[n] = v,
      isCapsule: proc(n: int): bool = false
    )

    let leq = newLinEqSolver()
    leq.setVariableResolver(vr)
    let eq1 = newPolynomial(3.0, Term(i: 1, c: -1.0), Term(i: 2, c: -1.0)) # a+b=3
    let eq2 = newPolynomial(1.0, Term(i: 2, c: -1.0)) # b=1
    discard leq.addEqs([eq1, eq2])

    check solved.hasKey(1)
    check solved.hasKey(2)
    check abs(solved[1] - 2.0) < 1.0e-7
    check abs(solved[2] - 1.0) < 1.0e-7

    let path =
      nullpath().knot(p(0, 0)).curve().knot(p(solved[1], solved[2])).curve().knot(
        p(3, 0)
      ).finish()
    let c = findHobbyControls(path, path.controls)

    let p0post = c.postControl(0)
    check abs(p0post.x - 0.2905) <= 0.0002
    check abs(p0post.y - 0.8159) <= 0.0002

    let p1pre = c.preControl(1)
    check abs(p1pre.x - 1.1730) <= 0.0002
    check abs(p1pre.y - 1.2572) <= 0.0002

    let p1post = c.postControl(1)
    check abs(p1post.x - 2.4776) <= 0.0002
    check abs(p1post.y - 0.8515) <= 0.0002

    let s = asString(path, c)
    check s ==
      "(0,0) .. controls (0.2905,0.8159) and (1.1730,1.2572)\n  .. (2,1) .. controls (2.4776,0.8515) and (2.8515,0.4776)\n  .. (3,0)"
