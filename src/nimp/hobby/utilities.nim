## Math/util helpers for hobby interpolation.

import std/[complex, math, strutils]

import nimp/pair

const
  PiVal* = 3.14159265
  Pi2Val* = 6.28318530
  EpsilonH* = 1.0e-7

proc isPairNaN*(pt: Pair): bool {.inline.} =
  isNaN(pt.x) or isNaN(pt.y)

proc isPairInf*(pt: Pair): bool {.inline.} =
  classify(pt.x) in {fcInf, fcNegInf} or classify(pt.y) in {fcInf, fcNegInf}

proc hobbyParamsAlphaBeta*(theta, phi: float64): (float64, float64) =
  const
    ConstA = 1.41421356
    ConstB = 0.0625
    ConstC = 0.38196601125
    ConstCC = 0.61803398875
  let st = sin(theta)
  let ct = cos(theta)
  let sf = sin(phi)
  let cf = cos(phi)
  let alpha = ConstA * (st - ConstB * sf) * (sf - ConstB * st) * (ct - cf)
  let beta = 1.0 + ConstCC * ct + ConstC * cf
  (alpha, beta)

proc hobbyParamsRhoSigma*(alpha, beta: float64): (float64, float64) =
  ((2.0 + alpha) / beta, (2.0 - alpha) / beta)

proc cunitvecs*(theta, phi: float64, dvec: Pair): (Pair, Pair) =
  let st = sin(theta)
  let ct = cos(theta)
  let sf = sin(phi)
  let cf = cos(phi)
  let dx = dvec.x
  let dy = dvec.y
  let uv1 = p(dx * ct - dy * st, dx * st + dy * ct)
  let uv2 = p(dx * cf + dy * sf, -dx * sf + dy * cf)
  (uv1, uv2)

proc controlPoints*(phi, theta, a, b: float64, dvec: Pair): (Pair, Pair) =
  let (alpha, beta) = hobbyParamsAlphaBeta(theta, phi)
  let (rho, sigma) = hobbyParamsRhoSigma(alpha, beta)
  let (uv1, uv2) = cunitvecs(theta, phi, dvec)
  let crho = p(a / 3.0 * rho, 0.0)
  let csigma = p(b / 3.0 * sigma, 0.0)
  let p2 = crho * uv1
  let p3 = csigma * uv2
  (p2, p3)

proc angle*(pr: Pair): float64 =
  if isPairNaN(pr):
    return 0.0
  phase(pr)

proc reduceAngle*(a: float64): float64 =
  if abs(a) > PiVal:
    if a > 0:
      return a - Pi2Val
    else:
      return a + Pi2Val
  a

proc recip*(a: float64): float64 =
  if isNaN(a): 1.0 else: 1.0 / a

proc square*(a: float64): float64 =
  a * a

proc rad2deg*(a: float64): float64 =
  a * 180.0 / PiVal

proc round4*(x: float64): float64 =
  if x >= 0:
    float(int64(x * 10000.0 + 0.5)) / 10000.0
  else:
    float(int64(x * 10000.0 - 0.5)) / 10000.0

proc trimFixed*(v: float64): string =
  var s = formatFloat(round4(v), ffDecimal, 4)
  while s.len > 0 and s[^1] == '0':
    s.setLen(s.len - 1)
  if s.len > 0 and s[^1] == '.':
    s.setLen(s.len - 1)
  if s.len == 0:
    s = "0"
  s

proc ptString*(pt: Pair, isControl: bool): string =
  if isPairNaN(pt):
    return "(<unknown>)"
  if isControl:
    return "(" & formatFloat(round4(pt.x), ffDecimal, 4) & "," &
      formatFloat(round4(pt.y), ffDecimal, 4) & ")"
  "(" & trimFixed(pt.x) & "," & trimFixed(pt.y) & ")"

# Compare two direction vectors by phase difference.
proc equalDir*(c1, c2: Pair): bool =
  abs(phase(c1 - c2)) < EpsilonH
