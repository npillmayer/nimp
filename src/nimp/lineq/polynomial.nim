## Sparse linear polynomial core.
##
## Polynomial form:
##   c + a1*x^1 + a2*x^2 + ... + an*x^n
##
## Terms are keyed by exponent i; key 0 is the constant term.

import std/[algorithm, sequtils, sets, strformat, strutils, tables]

import nimp/pair

type
  Term* = object
    i*: int
    c*: float64

  Polynomial* = object
    terms: Table[int, float64]

  PolynomialError* = object of CatchableError

# ---------------------------------------------------------------------------

proc copyPolynomial*(p: Polynomial): Polynomial =
  for i, c in p.terms:
    result.terms[i] = c

proc coeffForTerm*(p: Polynomial, i: int): float64 =
  if p.terms.hasKey(i):
    p.terms[i]
  else:
    0.0

proc `[]`*(p: Polynomial, i: int): float64 =
  coeffForTerm(p, i)

proc exponents*(p: Polynomial): seq[int] =
  result = p.terms.keys.toSeq
  sort(result)

proc zap*(p: Polynomial): Polynomial =
  result = p.copyPolynomial
  var zeroTerms: seq[int] = @[]
  for i, c in result.terms:
    if isZero(c):
      zeroTerms.add i
  for i in zeroTerms:
    result.terms.del(i)
  if not result.terms.hasKey(0):
    result.terms[0] = 0.0

proc newConstantPolynomial*(c: float64): Polynomial =
  result.terms[0] = c
  result = result.zap

proc setTerm*(p: var Polynomial, i: int, c: float64) =
  p.terms[i] = c

proc withTerm*(p: Polynomial, i: int, c: float64): Polynomial =
  result = p.copyPolynomial
  result.terms[i] = c
  result = result.zap

proc newPolynomial*(c: float64, tms: varargs[Term]): Polynomial =
  result = newConstantPolynomial(c)
  for tm in tms:
    if tm.i < 1:
      raise newException(ValueError, "term exponent must be at least 1")
    result.terms[tm.i] = tm.c
  result = result.zap

proc termCount*(p: Polynomial): int =
  p.zap.terms.len

proc isValid*(p: Polynomial): bool =
  p.terms.len > 0

proc isConstant*(p: Polynomial): tuple[c: float64, isConst: bool] =
  let pp = p.zap
  (pp.coeffForTerm(0), pp.terms.len == 1)

proc isVariable*(p: Polynomial): tuple[pos: int, ok: bool] =
  let pp = p.zap
  if pp.terms.len == 2 and isZero(pp.coeffForTerm(0)):
    let exps = pp.exponents
    let pos = exps[^1]
    let a = pp.coeffForTerm(pos)
    if isOne(a):
      return (pos, true)
  (-1, false)

proc isOff*(p: Polynomial): tuple[coeff: float64, off: bool] =
  let (c, isConst) = p.isConstant
  if isConst:
    return (c, true)
  (0.0, false)

proc add(p, q: Polynomial): Polynomial =
  result = p.copyPolynomial
  for i, c in q.terms:
    if not isZero(c):
      result.terms[i] = result.coeffForTerm(i) + c
  result = result.zap

proc `+`*(p, q: Polynomial): Polynomial =
  add(p, q)

proc subtract(p, q: Polynomial): Polynomial =
  result = p.copyPolynomial
  for i, c in q.terms:
    if not isZero(c):
      result.terms[i] = result.coeffForTerm(i) - c
  result = result.zap

proc `-`*(p, q: Polynomial): Polynomial =
  subtract(p, q)

proc multiply(p, q: Polynomial): Polynomial =
  let (qc, qIsConst) = q.isConstant
  let (pc, pIsConst) = p.isConstant
  var factor = 0.0
  var base: Polynomial
  if qIsConst:
    factor = qc
    base = p
  elif pIsConst:
    factor = pc
    base = q
  else:
    raise newException(
      PolynomialError, fmt"cannot multiply two non-constant polynomials: {$p} * {$q}"
    )
  result = base.copyPolynomial
  for i in base.exponents:
    result.terms[i] = zap(base.coeffForTerm(i) * factor)
  result = result.zap

proc `*`*(p, q: Polynomial): Polynomial =
  multiply(p, q)

proc divide(p, q: Polynomial): Polynomial =
  let (c, isConst) = q.isConstant
  if not isConst or isZero(c):
    raise newException(PolynomialError, fmt"illegal divisor polynomial: {$q}")
  p.multiply(newConstantPolynomial(1.0 / c))

proc `/`*(p, q: Polynomial): Polynomial =
  divide(p, q)

# substitute variable i within p with Polynomial p2 = replacement.
# If p does not contain a term.i, returns copy of p unchanged
proc substitute*(p: Polynomial, i: int, p2: Polynomial): Polynomial =
  if not isZero(p2.coeffForTerm(i)):
    raise newException(PolynomialError, fmt"cyclic substitution for term {i}: {$p2}")
  let scale = p.coeffForTerm(i)
  if isZero(scale):
    return p.copyPolynomial
  result = p.copyPolynomial
  result.terms.del(i)
  let expanded = p2.multiply(newConstantPolynomial(scale))
  result = result.add(expanded).zap

proc maxCoeff*(
    p: Polynomial, dependents: openArray[int] = []
): tuple[pos: int, coeff: float64] =
  var depSet = initHashSet[int]()
  for i in dependents:
    depSet.incl(i)
  var maxAbs = 0.0
  for i in p.exponents:
    if i == 0 or i in depSet:
      continue
    let c = p.coeffForTerm(i)
    if abs(c) > maxAbs:
      maxAbs = abs(c)
      result = (i, c)
  if result.pos == 0 and dependents.len > 0:
    return p.maxCoeff([])
  if result.pos == 0:
    raise newException(
      PolynomialError, "cannot determine max coefficient of constant polynomial"
    )

proc `$`*(p: Polynomial): string =
  let pp = p.zap
  var parts: seq[string] = @[]
  for i in pp.exponents:
    if i == 0:
      parts.add fmt"{{ {rounded(pp.coeffForTerm(0))} }}"
    else:
      parts.add fmt"{{ {rounded(pp.coeffForTerm(i))} x.{i} }}"
  parts.join(" ")
