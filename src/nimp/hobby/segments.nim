## Segment splitting and partial-path helpers for hobby solver.

import std/[complex]

import nimp/pair
import nimp/hobby/[builder, controls, types, utilities]

proc n*(pp: PathPartial): int =
  pp.`end` - pp.start + 1

proc isCycle*(pp: PathPartial): bool =
  pp.whole.isCycle and pp.whole.n == pp.n

proc pmap*(pp: PathPartial, i: int): int =
  (i mod pp.n) + pp.start

proc z*(pp: PathPartial, i: int): Pair =
  if pp.isCycle:
    return pp.whole.z(i)
  pp.whole.z(pp.pmap(i))

proc preDir*(pp: PathPartial, i: int): Pair =
  pp.whole.preDir(pp.pmap(i))

proc postDir*(pp: PathPartial, i: int): Pair =
  pp.whole.postDir(pp.pmap(i))

proc preCurl*(pp: PathPartial, i: int): float64 =
  pp.whole.preCurl(pp.pmap(i))

proc postCurl*(pp: PathPartial, i: int): float64 =
  pp.whole.postCurl(pp.pmap(i))

proc preTension*(pp: PathPartial, i: int): float64 =
  pp.whole.preTension(pp.pmap(i))

proc postTension*(pp: PathPartial, i: int): float64 =
  pp.whole.postTension(pp.pmap(i))

proc setPreControl*(pp: PathPartial, i: int, c: Pair) =
  pp.controls.setPreControl(pp.pmap(i), c)

proc setPostControl*(pp: PathPartial, i: int, c: Pair) =
  pp.controls.setPostControl(pp.pmap(i), c)

proc preControl*(pp: PathPartial, i: int): Pair =
  pp.controls.preControl(pp.pmap(i))

proc postControl*(pp: PathPartial, i: int): Pair =
  pp.controls.postControl(pp.pmap(i))

proc delta*(pp: PathPartial, i: int): Pair =
  pp.z(i + 1) - pp.z(i)

proc d*(pp: PathPartial, i: int): float64 =
  abs(pp.delta(i))

proc psi*(pp: PathPartial, i: int): float64 =
  var turning = 0.0
  if pp.isCycle or (i > 0 and i < pp.n - 1):
    turning = phase(pp.delta(i)) - phase(pp.delta(i - 1))
  reduceAngle(turning)

proc asStringPartial*(path: PathPartial, ctrls: Controls = nil): string =
  var s = ""
  for i in 0 ..< path.n:
    let pt = path.z(i)
    if i > 0:
      if not ctrls.isNil:
        s &= " and " & ptString(ctrls.preControl(path.pmap(i)), true) & "\n  .. "
      else:
        s &= " .. "
    s &= ptString(pt, false)
    if not ctrls.isNil and (i < path.n - 1 or path.isCycle):
      s &= " .. controls " & ptString(ctrls.postControl(path.pmap(i)), true)
  if path.isCycle:
    if not ctrls.isNil:
      s &= " and " & ptString(ctrls.preControl(path.pmap(0)), true) & "\n "
    s &= " .. cycle"
  s

proc makePathSegment*(path: Path, fromIdx, toIdx: int): PathPartial =
  PathPartial(whole: path, start: fromIdx, `end`: toIdx)

proc last*(path: Path): int =
  path.n - 1

proc isrough*(path: Path, i: int): bool =
  let lc = path.preCurl(i)
  let rc = path.postCurl(i)
  let hasCurl = lc != 1.0 or rc != 1.0
  let ld = path.preDir(i)
  let rd = path.postDir(i)
  let has2dirs = (not isPairNaN(ld) and not isPairNaN(rd)) and (not equalDir(ld, rd))
  hasCurl or has2dirs

proc splitSegments*(path: Path): seq[PathPartial] =
  var segCnt = 0
  var at = 0
  for i in 1 ..< path.n:
    if path.isrough(i):
      result.add makePathSegment(path, at, i)
      segCnt.inc
      at = i
  if path.isCycle:
    if segCnt == 0:
      result.add makePathSegment(path, 0, path.last)
    else:
      result.add makePathSegment(path, at, path.n)
  elif at != path.last:
    result.add makePathSegment(path, at, path.last)

proc validateSegment*(seg: PathPartial) =
  if seg.isNil or seg.whole.isNil:
    raise newException(NilPathError, "path must not be nil")
  if seg.n < 2:
    raise newException(TooFewKnotsError, "segment has too few knots")
  var limit = seg.n - 1
  if seg.isCycle:
    limit = seg.n
  for i in 0 ..< limit:
    if abs(seg.delta(i)) <= EpsilonH:
      raise newException(DegenerateSegmentError, "segment has degenerate edge")

proc delta*(path: Path, i: int): Pair =
  path.z(i + 1) - path.z(i)

proc d*(path: Path, i: int): float64 =
  abs(path.delta(i))

proc psi*(path: Path, i: int): float64 =
  var turning = 0.0
  if path.isCycle or (i > 0 and i < path.n - 1):
    turning = phase(path.delta(i)) - phase(path.delta(i - 1))
  reduceAngle(turning)
