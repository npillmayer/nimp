## Linear equation solver on top of sparse linear polynomials.

import std/[algorithm, sequtils, strformat, strutils, tables]

import nimp/pair
import nimp/lineq/polynomial

type
  EmptyEquationListError* = object of CatchableError
  InconsistentEquationError* = object of CatchableError
  LinEqStateError* = object of CatchableError

  VariableResolver* = ref object
    getVariableName*: proc(i: int): string {.closure.}
    setVariableSolved*: proc(i: int, value: float64) {.closure.}
    isCapsule*: proc(i: int): bool {.closure.}

  EquationMap* = Table[int, Polynomial]
  SolvedMap* = Table[int, Polynomial]

  LinEqSolver* = ref object
    dependents*: EquationMap
    solved*: SolvedMap
    varResolver*: VariableResolver
    showDependencies*: bool

proc sortedKeys[V](m: Table[int, V]): seq[int] =
  result = m.keys.toSeq
  sort(result)

proc newLinEqSolver*(): LinEqSolver =
  LinEqSolver(
    dependents: initTable[int, Polynomial](),
    solved: initTable[int, Polynomial](),
    showDependencies: false
  )

proc setVariableResolver*(leq: LinEqSolver, resolver: VariableResolver) =
  leq.varResolver = resolver

proc traceStringVar*(i: int, resolver: VariableResolver = nil): string =
  if not resolver.isNil and not resolver.getVariableName.isNil:
    return resolver.getVariableName(i)
  fmt"x.{i}"

proc traceString*(p: Polynomial, resolver: VariableResolver = nil): string =
  if resolver.isNil:
    return $p
  var parts: seq[string] = @[]
  var indent = false
  for pos in p.exponents:
    let scale = p.coeffForTerm(pos)
    if pos == 0:
      if not isZero(scale):
        parts.add $rounded(scale)
        indent = true
    elif not isZero(scale):
      if indent:
        if scale < 0.0:
          parts.add " - "
        else:
          parts.add " + "
      else:
        indent = true
        if scale < 0.0:
          parts.add "-"
      let absScale = abs(scale)
      if not isZero(absScale - 1.0):
        parts.add $rounded(absScale)
      parts.add traceStringVar(pos, resolver)
  if parts.len == 0:
    return "0"
  parts.join("")

proc getSolvedVars*(leq: LinEqSolver): Table[int, float64] =
  result = initTable[int, float64]()
  for i in sortedKeys(leq.solved):
    if leq.solved.hasKey(i):
      result[i] = leq.solved[i].coeffForTerm(0)

proc termContains(p: Polynomial, i: int): bool =
  not isZero(p.coeffForTerm(i))

proc solvedPolynomial(p: Polynomial): tuple[ok: bool, rhs: Polynomial] =
  let (value, isConst) = p.isConstant
  if isConst:
    return (true, p.withTerm(0, rounded(value)))
  (false, p)

proc termLength(p: Polynomial): int =
  p.termCount

proc varString(leq: LinEqSolver, i: int): string =
  traceStringVar(i, leq.varResolver)

proc polynString(leq: LinEqSolver, p: Polynomial): string =
  traceString(p, leq.varResolver)

proc updateDependency(leq: LinEqSolver, i: int, p: Polynomial, m: var EquationMap) =
  let rhs = p.copyPolynomial
  if m.hasKey(i):
    if termLength(rhs) < termLength(m[i]):
      m[i] = rhs
  else:
    m[i] = rhs

proc subst(i: int, p0: Polynomial, j0: int, q0: Polynomial): (int, Polynomial) =
  var p = p0.copyPolynomial
  var q = q0.copyPolynomial
  var j = j0
  let ai = q.coeffForTerm(i)
  if not isZero(ai):
    q.setTerm(i, 0.0)
    q = q.zap
    p = p * newConstantPolynomial(ai)
    q = (q + p).zap
    let aj = q.coeffForTerm(j)
    if isZero(aj):
      discard
    elif isOne(aj):
      q.setTerm(j, 0.0)
      q = q.zap
      j = 0
    else:
      let scale = -1.0 / (aj - 1.0)
      q.setTerm(j, 0.0)
      q = q.zap
      q = (q * newConstantPolynomial(scale)).zap
  (j, q)

proc substituteSolved(leq: LinEqSolver, j: int, p0: Polynomial, solved: SolvedMap): Polynomial =
  result = p0.copyPolynomial
  for i in sortedKeys(solved):
    if not solved.hasKey(i):
      continue
    let rhs = solved[i]
    let c = rhs.coeffForTerm(0)
    let coeff = result.coeffForTerm(i)
    if not isZero(coeff):
      let pc = result.coeffForTerm(0)
      result.setTerm(0, pc + coeff * c)
      result.setTerm(i, 0.0)
      result = result.zap
      discard j

proc activateEquationTowards(leq: LinEqSolver, i: int, p0: Polynomial): Polynomial =
  let coeff = p0.coeffForTerm(i)
  if isZero(coeff):
    raise newException(LinEqStateError,
      fmt"cannot activate equation towards {leq.varString(i)}: zero coefficient")
  result = p0.copyPolynomial
  result.setTerm(i, 0.0)
  result = result.zap
  result = (result * newConstantPolynomial(-1.0 / coeff)).zap

proc setSolved(leq: LinEqSolver, i: int, p: Polynomial) =
  let c = p.coeffForTerm(0)
  leq.solved[i] = p
  if not leq.varResolver.isNil and not leq.varResolver.setVariableSolved.isNil:
    leq.varResolver.setVariableSolved(i, c)

proc checkAndCountCapsule(leq: LinEqSolver, i: int, counts: var Table[int, int]) =
  if not leq.varResolver.isNil and not leq.varResolver.isCapsule.isNil and leq.varResolver.isCapsule(i):
    counts[i] = counts.getOrDefault(i) + 1

proc retractVariable*(leq: LinEqSolver, i: int) =
  if leq.solved.hasKey(i):
    leq.solved.del(i)
  if leq.dependents.hasKey(i):
    leq.dependents.del(i)
  var marked: seq[int] = @[]
  for j in sortedKeys(leq.dependents):
    if leq.dependents.hasKey(j):
      let p = leq.dependents[j]
      if not isZero(p.coeffForTerm(i)):
        marked.add(j)
  for j in marked:
    if leq.dependents.hasKey(j):
      leq.dependents.del(j)

proc harvestCapsules*(leq: LinEqSolver) =
  if leq.varResolver.isNil or leq.varResolver.isCapsule.isNil:
    return
  var counts = initTable[int, int]()
  for w in sortedKeys(leq.dependents):
    if not leq.dependents.hasKey(w):
      continue
    let pw = leq.dependents[w]
    leq.checkAndCountCapsule(w, counts)
    for i in pw.exponents:
      if i > 0:
        leq.checkAndCountCapsule(i, counts)
  for j in sortedKeys(leq.solved):
    if leq.solved.hasKey(j):
      leq.checkAndCountCapsule(j, counts)
  for pos in sortedKeys(counts):
    if counts[pos] == 1:
      leq.retractVariable(pos)

proc updateDependentVariables(leq: LinEqSolver, i0: int, p0: Polynomial): EquationMap =
  var d = initTable[int, Polynomial]()
  leq.updateDependency(i0, p0, d)
  for j0 in sortedKeys(leq.dependents):
    if not leq.dependents.hasKey(j0):
      continue
    var i = i0
    if not d.hasKey(i):
      raise newException(LinEqStateError,
        fmt"internal solver state missing dependency for {leq.varString(i)}")
    var p = d[i].copyPolynomial
    var j = j0
    var q = leq.dependents[j0]
    if j == i:
      let (k, _) = q.maxCoeff(sortedKeys(d))
      var lhs = newConstantPolynomial(0.0)
      lhs.setTerm(j, -1.0)
      q = q + lhs
      q = leq.activateEquationTowards(k, q)
      j = k
    leq.updateDependency(j, q, d)
    if (not termContains(q, i)) and termContains(p, j):
      swap(i, j)
      swap(p, q)
    if termContains(q, i):
      (j, q) = subst(i, p, j, q)
      if j != 0:
        leq.updateDependency(j, q, d)
      else:
        let (coeff, off) = q.isOff
        if not off:
          let (k, _) = q.maxCoeff(sortedKeys(d))
          q = leq.activateEquationTowards(k, q)
          leq.updateDependency(k, q, d)
        elif not isZero(coeff):
          raise newException(InconsistentEquationError,
            fmt"0 = {leq.polynString(q)} (off by {coeff})")
  d

proc addEqInternal(leq: LinEqSolver, p0: Polynomial, cont: bool) =
  var p = p0.zap
  p = leq.substituteSolved(0, p, leq.solved)
  let (coeff, off) = p.isOff
  if not off:
    let (i, _) = p.maxCoeff(sortedKeys(leq.dependents))
    p = leq.activateEquationTowards(i, p)
    var d = leq.updateDependentVariables(i, p)
    var s = initTable[int, Polynomial]()
    for k in sortedKeys(d):
      if not d.hasKey(k):
        continue
      let (ok, rhs) = solvedPolynomial(d[k])
      if ok:
        s[k] = rhs
        d.del(k)
    for k in sortedKeys(d):
      if not d.hasKey(k):
        continue
      let reduced = leq.substituteSolved(k, d[k], s)
      let (ok, rhs) = solvedPolynomial(reduced)
      if ok:
        s[k] = rhs
        d.del(k)
      else:
        d[k] = reduced
    for k in sortedKeys(s):
      if s.hasKey(k):
        leq.setSolved(k, s[k])
    leq.dependents = d
  elif not isZero(coeff):
    raise newException(InconsistentEquationError,
      fmt"0 = {leq.polynString(p)} (off by {coeff})")

  if not cont:
    leq.harvestCapsules()

proc addEq*(leq: LinEqSolver, p: Polynomial): LinEqSolver =
  leq.addEqInternal(p, false)
  leq

proc addEqs*(leq: LinEqSolver, plist: openArray[Polynomial]): LinEqSolver =
  if plist.len == 0:
    raise newException(EmptyEquationListError, "empty list of equations")
  for i, p in plist:
    leq.addEqInternal(p, i + 1 < plist.len)
  leq

proc dump*(leq: LinEqSolver, resolv: VariableResolver = nil): string =
  let resolver = if resolv.isNil: leq.varResolver else: resolv
  var lines = @["----------------------------------------------------------------------",
    "Dependents:                                                        LEQ"]
  for k in sortedKeys(leq.dependents):
    if leq.dependents.hasKey(k):
      lines.add fmt"	{traceStringVar(k, resolver)} = {traceString(leq.dependents[k], resolver)}"
  lines.add("Solved:")
  for k in sortedKeys(leq.solved):
    if leq.solved.hasKey(k):
      lines.add fmt"	{traceStringVar(k, resolver)} = {leq.solved[k].coeffForTerm(0)}"
  lines.add("----------------------------------------------------------------------")
  lines.join("\n")
