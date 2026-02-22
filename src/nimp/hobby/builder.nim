## Builder and accessors for Hobby paths.

import nimp/pair
import nimp/hobby/types

proc extendPair(arr: var seq[Pair], i: int, deflt: Pair) =
  if i < 0:
    raise newException(ValueError, "index must be >= 0")
  if i >= arr.len:
    let oldLen = arr.len
    arr.setLen(i + 1)
    for k in oldLen .. i:
      arr[k] = deflt

proc getPair(arr: seq[Pair], i: int, deflt: Pair): Pair =
  if i < 0 or i >= arr.len:
    return deflt
  arr[i]

proc nullpath*(): Path =
  newPath()

proc finish*(path: Path): Path =
  path

proc `end`*(path: Path): Path =
  path.finish()

proc cycle*(path: Path): Path =
  path.cycleFlag = true
  path

proc knot*(path: Path, pt: Pair): Path =
  path.points.add(pt)
  path

proc smoothKnot*(path: Path, pt: Pair): Path =
  path.knot(pt)

proc setPreDir*(path: Path, i: int, dir: Pair): Path =
  path.predirs.extendPair(i, nanPair())
  path.predirs[i] = dir
  path

proc setPostDir*(path: Path, i: int, dir: Pair): Path =
  path.postdirs.extendPair(i, nanPair())
  path.postdirs[i] = dir
  path

proc n*(path: Path): int =
  path.points.len

proc setPreCurl*(path: Path, i: int, curl: float64): Path =
  path.curls.extendPair(i, p(1.0, 1.0))
  let c = path.curls[i]
  path.curls[i] = p(curl, c.y)
  path

proc setPostCurl*(path: Path, i: int, curl: float64): Path =
  path.curls.extendPair(i, p(1.0, 1.0))
  let c = path.curls[i]
  path.curls[i] = p(c.x, curl)
  path

proc setPreTension*(path: Path, i: int, tension: float64): Path =
  path.tensions.extendPair(i, p(1.0, 1.0))
  let t = path.tensions[i]
  var clamped = tension
  if clamped < 0.75:
    clamped = 0.75
  elif clamped > 4.0:
    clamped = 4.0
  path.tensions[i] = p(clamped, t.y)
  path

proc setPostTension*(path: Path, i: int, tension: float64): Path =
  path.tensions.extendPair(i, p(1.0, 1.0))
  let t = path.tensions[i]
  var clamped = tension
  if clamped < 0.75:
    clamped = 0.75
  elif clamped > 4.0:
    clamped = 4.0
  path.tensions[i] = p(t.x, clamped)
  path

proc curlKnot*(path: Path, pt: Pair, preCurl, postCurl: float64): Path =
  discard path.knot(pt)
  discard path.setPreCurl(path.n - 1, preCurl)
  discard path.setPostCurl(path.n - 1, postCurl)
  path

proc dirKnot*(path: Path, pt: Pair, dir: Pair): Path =
  discard path.knot(pt)
  discard path.setPreDir(path.n - 1, dir)
  discard path.setPostDir(path.n - 1, dir)
  path

proc line*(path: Path): Path =
  if path.n == 0:
    raise newException(ValueError, "cannot add line to empty path")
  discard path.setPostCurl(path.n - 1, 1.0)
  discard path.setPreCurl(path.n, 1.0)
  path

proc tensionCurve*(path: Path, t1, t2: float64): Path =
  if path.n == 0:
    raise newException(ValueError, "cannot add curve to empty path")
  if t1 != 1.0:
    discard path.setPostTension(path.n - 1, t1)
  if t2 != 1.0:
    discard path.setPreTension(path.n, t2)
  path

proc curve*(path: Path): Path =
  if path.n == 0:
    raise newException(ValueError, "cannot add curve to empty path")
  path.tensionCurve(1.0, 1.0)

proc appendSubpath*(path: Path, sp: Path): Path =
  discard sp
  path

proc isCycle*(path: Path): bool =
  path.cycleFlag

proc z*(path: Path, i: int): Pair =
  if path.n == 0:
    raise newException(ValueError, "cannot index empty path")
  var idx = i
  if i < 0 or i >= path.n:
    idx = i mod path.n
  path.points[idx]

proc preDir*(path: Path, i: int): Pair =
  getPair(path.predirs, i, nanPair())

proc postDir*(path: Path, i: int): Pair =
  getPair(path.postdirs, i, nanPair())

proc preCurl*(path: Path, i: int): float64 =
  getPair(path.curls, i, p(1.0, 1.0)).x

proc postCurl*(path: Path, i: int): float64 =
  getPair(path.curls, i, p(1.0, 1.0)).y

proc preTension*(path: Path, i: int): float64 =
  getPair(path.tensions, i, p(1.0, 1.0)).x

proc postTension*(path: Path, i: int): float64 =
  getPair(path.tensions, i, p(1.0, 1.0)).y
