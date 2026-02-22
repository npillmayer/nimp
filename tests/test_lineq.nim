import std/[sets, strutils, tables, unittest]

import nimp

type TestResolver = ref object
  solved: Table[int, float64]
  capsules: HashSet[int]

proc newTestResolver(caps: openArray[int] = []): (TestResolver, VariableResolver) =
  let tr = TestResolver(
    solved: initTable[int, float64](),
    capsules: initHashSet[int]()
  )
  for c in caps:
    tr.capsules.incl(c)
  let vr = VariableResolver(
    getVariableName: proc(n: int): string =
      if n in 1..26:
        $(chr(n + 96))
      else:
        "x." & $n,
    setVariableSolved: proc(n: int, v: float64) =
      tr.solved[n] = v,
    isCapsule: proc(n: int): bool =
      n in tr.capsules
  )
  (tr, vr)

proc assertBefore(s, first, second: string) =
  let iFirst = s.find(first)
  let iSecond = s.find(second)
  doAssert iFirst >= 0, "missing substring: " & first
  doAssert iSecond >= 0, "missing substring: " & second
  doAssert iFirst < iSecond, first & " should appear before " & second

suite "lineq solver":
  test "new solver":
    let leq = newLinEqSolver()
    check not leq.isNil

  test "add single equation solves variable":
    let leq = newLinEqSolver()
    let (r, vr) = newTestResolver()
    leq.setVariableResolver(vr)
    let p = newPolynomial(1.0, Term(i: 1, c: 2.0))
    discard leq.addEq(p)
    check r.solved.hasKey(1)

  test "simple 2x2 system":
    let leq = newLinEqSolver()
    let (r, vr) = newTestResolver()
    leq.setVariableResolver(vr)
    let p = newPolynomial(6.0, Term(i: 1, c: -1.0), Term(i: 2, c: -1.0))
    let q = newPolynomial(2.0, Term(i: 1, c: 3.0), Term(i: 2, c: -1.0))
    discard leq.addEq(p)
    discard leq.addEq(q)
    check abs(r.solved[1] - 1.0) < 1.0e-7
    check abs(r.solved[2] - 5.0) < 1.0e-7

  test "addEqs empty list":
    let leq = newLinEqSolver()
    expect(EmptyEquationListError):
      discard leq.addEqs(@[])

  test "inconsistent equations":
    let leq = newLinEqSolver()
    let p1 = newPolynomial(100.0, Term(i: 1, c: -1.0))
    let p2 = newPolynomial(99.0, Term(i: 1, c: -2.0))
    discard leq.addEq(p1)
    expect(InconsistentEquationError):
      discard leq.addEq(p2)

  test "getSolvedVars snapshot":
    let leq = newLinEqSolver()
    let p = newPolynomial(1.0, Term(i: 1, c: 2.0))
    discard leq.addEq(p)
    let solved = leq.getSolvedVars()
    check solved.hasKey(1)
    check abs(solved[1] + 0.5) < 1.0e-7

  test "harvest capsules":
    let leq = newLinEqSolver()
    let (_, vr) = newTestResolver([5, 6])
    leq.setVariableResolver(vr)
    leq.dependents[2] = newConstantPolynomial(0.0).withTerm(5, 1.0)
    leq.dependents[3] = newConstantPolynomial(1.0).withTerm(5, 1.0)
    leq.dependents[4] = newConstantPolynomial(0.0).withTerm(6, 1.0)
    leq.harvestCapsules()
    check leq.dependents.hasKey(2)
    check leq.dependents.hasKey(3)
    check not leq.dependents.hasKey(4)

  test "capsule in solved gets retracted":
    let leq = newLinEqSolver()
    let (_, vr) = newTestResolver([8])
    leq.setVariableResolver(vr)
    leq.solved[8] = newConstantPolynomial(42.0)
    leq.harvestCapsules()
    check not leq.solved.hasKey(8)

  test "dump deterministic ordering":
    let leq = newLinEqSolver()
    leq.dependents[9] = newConstantPolynomial(1.0).withTerm(9, 1.0)
    leq.dependents[2] = newConstantPolynomial(1.0).withTerm(2, 1.0)
    leq.dependents[5] = newConstantPolynomial(1.0).withTerm(5, 1.0)
    leq.solved[8] = newConstantPolynomial(8.0)
    leq.solved[1] = newConstantPolynomial(1.0)
    let dumpText = leq.dump()
    assertBefore(dumpText, "\tx.2 =", "\tx.5 =")
    assertBefore(dumpText, "\tx.5 =", "\tx.9 =")
    assertBefore(dumpText, "\tx.1 =", "\tx.8 =")

  test "harvest does not remove non-capsules":
    let leq = newLinEqSolver()
    let (_, vr) = newTestResolver([9])
    leq.setVariableResolver(vr)
    leq.dependents[7] = newConstantPolynomial(0.0).withTerm(7, 1.0)
    leq.harvestCapsules()
    check leq.dependents.hasKey(7)

  test "addEqs solves simple system":
    let leq = newLinEqSolver()
    let (r, vr) = newTestResolver()
    leq.setVariableResolver(vr)
    let p = newPolynomial(6.0, Term(i: 1, c: -1.0), Term(i: 2, c: -1.0))
    let q = newPolynomial(2.0, Term(i: 1, c: 3.0), Term(i: 2, c: -1.0))
    discard leq.addEqs([p, q])
    check abs(r.solved[1] - 1.0) < 1.0e-7
    check abs(r.solved[2] - 5.0) < 1.0e-7

  test "LEQ4 dependent elimination solves target variable":
    let leq = newLinEqSolver()
    let (r, vr) = newTestResolver()
    leq.setVariableResolver(vr)
    let p1 = newPolynomial(100.0, Term(i: 1, c: -1.0))
    let p2 = newPolynomial(0.0,
      Term(i: 1, c: 2.0), Term(i: 2, c: -1.0), Term(i: 3, c: 1.0), Term(i: 4, c: 4.0))
    let p3 = newPolynomial(0.0, Term(i: 2, c: 1.0), Term(i: 3, c: -1.0))
    discard leq.addEq(p1)
    discard leq.addEq(p2)
    discard leq.addEq(p3)
    check r.solved.hasKey(4)

  test "LEQ5 cycle dependencies keep compact relation":
    let leq = newLinEqSolver()
    let (_, vr) = newTestResolver()
    leq.setVariableResolver(vr)
    let p1 = newPolynomial(0.0, Term(i: 2, c: -1.0), Term(i: 3, c: 1.0))
    let p2 = newPolynomial(0.0, Term(i: 3, c: -1.0), Term(i: 4, c: 1.0))
    let p3 = newPolynomial(0.0, Term(i: 4, c: -1.0), Term(i: 2, c: 1.0))
    let p4 = newPolynomial(0.0,
      Term(i: 1, c: -1.0), Term(i: 2, c: 1.0), Term(i: 3, c: 1.0), Term(i: 4, c: 1.0))
    discard leq.addEq(p1)
    discard leq.addEq(p2)
    discard leq.addEq(p3)
    discard leq.addEq(p4)
    check leq.dependents.hasKey(1)
    check leq.dependents[1].termCount == 2
