import std/unittest

import nimp

suite "polynomial core":
  test "constant polynomial":
    let p = newConstantPolynomial(1.0)
    let (c, isConst) = p.isConstant
    check isConst
    check abs(c - 1.0) < 1.0e-12
    check p.termCount == 1

  test "constructor with terms":
    let p = newPolynomial(5.0, Term(i: 2, c: 2.0), Term(i: 1, c: 1.0))
    check p.exponents == @[0, 1, 2]
    check abs(p.coeffForTerm(2) - 2.0) < 1.0e-12

  test "constructor rejects illegal exponent":
    expect(ValueError):
      discard newPolynomial(0.0, Term(i: 0, c: 1.0))

  test "bracket notatation for term access":
    let p = newPolynomial(5.0, Term(i: 2, c: 2.0), Term(i: 1, c: 1.0))
    let x2 = p[2] # get coefficient for term with exponent 2
    check abs(x2 - 2.0) < 1.0e-12

  test "add and subtract":
    let p = newPolynomial(10.0, Term(i: 1, c: 7.0), Term(i: 2, c: 2.0))
    #let q = newPolynomial(4.0, Term(i: 1, c: 2.0), Term(i: 3, c: 9.0))
    let q = newConstantPolynomial(4.0).withTerm(1, 2.0).withTerm(3, 9.0)
    let sum = p + q
    let diff = p - q
    check abs(sum.coeffForTerm(0) - 14.0) < 1.0e-12
    check abs(sum.coeffForTerm(1) - 9.0) < 1.0e-12
    check abs(diff.coeffForTerm(0) - 6.0) < 1.0e-12
    check abs(diff.coeffForTerm(1) - 5.0) < 1.0e-12
    check abs(diff.coeffForTerm(2) - 2.0) < 1.0e-12
    check abs(diff.coeffForTerm(3) + 9.0) < 1.0e-12

  test "multiply and divide by constant":
    let p = newPolynomial(6.0, Term(i: 1, c: 4.0), Term(i: 2, c: 2.0))
    let m = p * newConstantPolynomial(-2.0)
    check abs(m.coeffForTerm(1) + 8.0) < 1.0e-12
    let d = p / newConstantPolynomial(2.0)
    check abs(d.coeffForTerm(0) - 3.0) < 1.0e-12
    check abs(d.coeffForTerm(1) - 2.0) < 1.0e-12

  test "multiply rejects non-constant product":
    let p = newPolynomial(1.0, Term(i: 1, c: 2.0))
    let q = newPolynomial(1.0, Term(i: 2, c: 3.0))
    expect(PolynomialError):
      discard p * q

  test "divide rejects invalid divisor":
    let p = newPolynomial(6.0, Term(i: 1, c: 4.0))
    expect(PolynomialError):
      discard p / newConstantPolynomial(0.0)
    let q = newPolynomial(1.0, Term(i: 2, c: 1.0))
    expect(PolynomialError):
      discard p / q

  test "zap removes zero-like terms and keeps constant term":
    let p = newPolynomial(0.5, Term(i: 1, c: 0.5e-9))
    let z = p.zap
    let (_, isConst) = z.isConstant
    check isConst
    check z.termCount == 1

  test "operations are pure":
    let p = newPolynomial(5.0, Term(i: 1, c: 1.0), Term(i: 2, c: 2.0))
    let q = newPolynomial(4.0, Term(i: 1, c: 6.0), Term(i: 5, c: 4.0))
    discard p + q
    check abs(p.coeffForTerm(1) - 1.0) < 1.0e-12
    check abs(q.coeffForTerm(5) - 4.0) < 1.0e-12

  test "substitute term":
    let p = newPolynomial(1.0, Term(i: 1, c: 10.0), Term(i: 2, c: 20.0))
    let replacement = newPolynomial(2.0, Term(i: 3, c: 30.0), Term(i: 4, c: 40.0))
    let r = p.substitute(1, replacement)
    # p.x1 had coeff = 10.0
    check abs(r.coeffForTerm(0) - 21.0) < 1.0e-12 # 2.0 * 10.0 + 1.0
    check abs(r.coeffForTerm(1) - 0.0) < 1.0e-12 # replaced
    check abs(r.coeffForTerm(2) - 20.0) < 1.0e-12 # untouched
    check abs(r.coeffForTerm(3) - 300.0) < 1.0e-12 # scaled by 10.0
    check abs(r.coeffForTerm(4) - 400.0) < 1.0e-12 # scaled by 10.0

  test "maxCoeff with dependent skip":
    let p =
      newPolynomial(0.0, Term(i: 1, c: 5.0), Term(i: 2, c: -5.0), Term(i: 4, c: 5.0))
    let (i, c) = p.maxCoeff()
    check i == 1
    check abs(c - 5.0) < 1.0e-12
    let (j, d) = p.maxCoeff([1])
    check j == 2
    check abs(d + 5.0) < 1.0e-12
