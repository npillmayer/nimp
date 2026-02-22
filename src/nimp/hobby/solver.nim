## Hobby control-point solver (open and cyclic paths).

import std/complex

import nimp/hobby/[builder, controls, segments, types, utilities]

proc validateForSolve*(path: Path) =
  if path.isNil:
    raise newException(NilPathError, "path must not be nil")
  let n = path.n
  if path.isCycle:
    if n < 3:
      raise newException(TooFewKnotsError, "cycle needs at least 3 knots")
    if abs(path.points[0] - path.points[n - 1]) <= EpsilonH:
      raise newException(DuplicateCycleTerminalKnotError,
        "cycle path must not repeat first knot as terminal knot")
  elif n < 2:
    raise newException(TooFewKnotsError, "open path needs at least 2 knots")

  for i in 0 ..< n:
    let z = path.points[i]
    if isPairNaN(z) or isPairInf(z):
      raise newException(InvalidKnotError, "path has invalid knot coordinate")

  var limit = n - 1
  if path.isCycle:
    limit = n
  for i in 0 ..< limit:
    var j = i + 1
    if path.isCycle:
      j = (i + 1) mod n
    if abs(path.points[j] - path.points[i]) <= EpsilonH:
      raise newException(DegenerateSegmentError, "path has degenerate segment")

proc startOpen(path: PathPartial, theta, u, v: var seq[float64]) =
  if isPairNaN(path.postDir(0)):
    let a = recip(path.postTension(0))
    let b = recip(path.preTension(1))
    let c = square(a) * path.postCurl(0) / square(b)
    u[0] = ((3.0 - a) * c + b) / (a * c + 3.0 - b)
    v[0] = -u[0] * path.psi(1)
  else:
    u[0] = 0.0
    v[0] = reduceAngle(angle(path.postDir(0)) - angle(path.delta(0)))

proc endOpen(path: PathPartial, theta, u, v: var seq[float64]) =
  let last = path.n - 1
  if isPairNaN(path.preDir(last)):
    let a = recip(path.postTension(last - 1))
    let b = recip(path.preTension(last))
    let c = square(b) * path.preCurl(last) / square(a)
    u[last] = (b * c + 3.0 - a) / ((3.0 - b) * c + a)
    theta[last] = v[last - 1] / (u[last - 1] - u[last])
  else:
    theta[last] = reduceAngle(angle(path.preDir(last)) - angle(path.delta(last - 1)))

  if last > 0:
    for i in countdown(last - 1, 0):
      theta[i] = v[i] - u[i] * theta[i + 1]

proc startCycle(path: PathPartial, theta, u, v, w: var seq[float64]) =
  discard path
  discard theta
  u[0] = 0.0
  v[0] = 0.0
  w[0] = 1.0

proc endCycle(path: PathPartial, theta, u, v, w: var seq[float64]) =
  let n = path.n
  var a = 0.0
  var b = 1.0
  for i in countdown(n, 1):
    a = v[i] - a * u[i]
    b = w[i] - b * u[i]
  let t0 = (v[n] - a * u[n]) / (1.0 - (w[n] - b * u[n]))
  v[0] = t0
  for i in 1 .. n:
    v[i] += w[i] * t0
  theta[0] = t0
  theta[n] = t0
  if n > 1:
    for i in countdown(n - 1, 1):
      theta[i] = v[i] - u[i] * theta[i + 1]

proc buildEqs(path: PathPartial, u, v: var seq[float64], w: var seq[float64]) =
  let n = path.n
  for i in 1 .. n:
    let a0 = recip(path.postTension(i - 1))
    let a1 = recip(path.postTension(i))
    let b1 = recip(path.preTension(i))
    let b2 = recip(path.preTension(i + 1))
    let a = a0 / (square(b1) * path.d(i - 1))
    let b = (3.0 - a0) / (square(b1) * path.d(i - 1))
    let c = (3.0 - b2) / (square(a1) * path.d(i))
    let d = b2 / (square(a1) * path.d(i))
    let t = b - u[i - 1] * a + c
    u[i] = d / t
    v[i] = (-b * path.psi(i) - d * path.psi(i + 1) - a * v[i - 1]) / t
    if path.isCycle:
      w[i] = -a * w[i - 1] / t

proc solveOpenPath(path: PathPartial, theta, u, v: var seq[float64]) =
  startOpen(path, theta, u, v)
  var dummyW = newSeq[float64](0)
  buildEqs(path, u, v, dummyW)
  endOpen(path, theta, u, v)

proc solveCyclePath(path: PathPartial, theta, u, v, w: var seq[float64]) =
  startCycle(path, theta, u, v, w)
  buildEqs(path, u, v, w)
  endCycle(path, theta, u, v, w)

proc setControls(path: PathPartial, theta: seq[float64], controls: Controls): Controls =
  let n = path.n
  for i in 0 ..< n:
    let phi = -path.psi(i + 1) - theta[i + 1]
    let a = recip(path.postTension(i))
    let b = recip(path.preTension(i + 1))
    let dvec = path.delta(i)
    let (p2, p3) = controlPoints(phi, theta[i], a, b, dvec)
    controls.setPostControl(i mod n, path.z(i) + p2)
    controls.setPreControl((i + 1) mod n, path.z(i + 1) - p3)
  controls

proc findSegmentControls(path: PathPartial, controls: Controls): Controls =
  var u = newSeq[float64](path.n + 2)
  var v = newSeq[float64](path.n + 2)
  var theta = newSeq[float64](path.n + 2)
  if path.isCycle:
    var w = newSeq[float64](path.n + 2)
    solveCyclePath(path, theta, u, v, w)
  else:
    solveOpenPath(path, theta, u, v)
  setControls(path, theta, controls)

proc findHobbyControls*(path: Path, controls: Controls = nil): Controls =
  path.validateForSolve()
  var ctrls = controls
  if ctrls.isNil:
    ctrls = newControls()
  let segs = splitSegments(path)
  for seg in segs:
    seg.validateSegment()
    seg.controls = ctrls
    discard findSegmentControls(seg, ctrls)
  ctrls

proc mustFindHobbyControls*(path: Path, controls: Controls = nil): Controls =
  findHobbyControls(path, controls)
