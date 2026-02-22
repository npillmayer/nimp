import std/unittest

import nimp

proc mustFindControls(path: Path, controls: Controls = nil): Controls =
  findHobbyControls(path, controls)

proc testPath(): (Path, Controls) =
  let path = nullpath().knot(p(1, 1)).curve().knot(p(2, 2)).curve().knot(p(3, 1)).finish()
  (path, path.controls)

suite "hobby solver":
  test "open path solve":
    let (path, controls) = testPath()
    let c = mustFindControls(path, controls)
    check not isPairNaN(c.postControl(0))
    check not isPairNaN(c.preControl(1))

  test "cycle snapshot controls":
    let path =
      nullpath().knot(p(1, 1)).curve().knot(p(2, 2)).curve().knot(p(3, 1)).curve().knot(
        p(2, 0)
      ).curve().cycle()
    let controls = mustFindControls(path, path.controls)
    let p0post = controls.postControl(0)
    check abs(p0post.x - 1.0000) <= 0.0003
    check abs(p0post.y - 1.5523) <= 0.0003

    let p1pre = controls.preControl(1)
    check abs(p1pre.x - 1.4477) <= 0.0003
    check abs(p1pre.y - 2.0000) <= 0.0003

    let p2post = controls.postControl(2)
    check abs(p2post.x - 3.0000) <= 0.0003
    check abs(p2post.y - 0.4477) <= 0.0003

  test "segment splitting baseline":
    let path =
      nullpath().knot(p(0, 0)).curve().knot(p(0, 3)).curve().knot(p(5, 3)).line().dirKnot(
        p(3, -1), p(0, -1)
      ).curve().cycle()
    let segs = splitSegments(path)
    check segs.len == 1

    let roughPath = nullpath().knot(p(0, 0)).curve().knot(p(1, 1)).curve().knot(p(2, 0)).finish()
    discard roughPath.setPreCurl(1, 2.0)
    let rsegs = splitSegments(roughPath)
    check rsegs.len == 2
    check rsegs[0].start == 0
    check rsegs[0].`end` == 1
    check rsegs[1].start == 1
    check rsegs[1].`end` == 2

  test "reject nil path":
    expect(NilPathError):
      discard findHobbyControls(nil, nil)

  test "reject too few knots open":
    let path = nullpath().knot(p(0, 0)).finish()
    expect(TooFewKnotsError):
      discard findHobbyControls(path, path.controls)

  test "reject too few knots cycle":
    let path = nullpath().knot(p(0, 0)).curve().knot(p(1, 0)).curve().cycle()
    expect(TooFewKnotsError):
      discard findHobbyControls(path, path.controls)

  test "reject degenerate segment":
    let path = nullpath().knot(p(0, 0)).curve().knot(p(0, 0)).finish()
    expect(DegenerateSegmentError):
      discard findHobbyControls(path, path.controls)

  test "reject near-degenerate segment within epsilon":
    let path = nullpath().knot(p(0, 0)).curve().knot(p(EpsilonH / 2.0, 0)).finish()
    expect(DegenerateSegmentError):
      discard findHobbyControls(path, path.controls)

  test "reject invalid knot":
    let path = nullpath().knot(p(0, 0)).curve().knot(p(NaN, 0)).finish()
    expect(InvalidKnotError):
      discard findHobbyControls(path, path.controls)

  test "reject infinite knot":
    let path = nullpath().knot(p(0, 0)).curve().knot(p(Inf, 0)).finish()
    expect(InvalidKnotError):
      discard findHobbyControls(path, path.controls)

  test "reject duplicate cycle terminal knot":
    let path =
      nullpath().knot(p(0, 0)).curve().knot(p(1, 0)).curve().knot(p(0, 0)).curve().cycle()
    expect(DuplicateCycleTerminalKnotError):
      discard findHobbyControls(path, path.controls)

  test "reject near-duplicate cycle terminal knot":
    let path =
      nullpath().knot(p(0, 0)).curve().knot(p(1, 0)).curve().knot(p(EpsilonH / 2.0, 0)).curve().cycle()
    expect(DuplicateCycleTerminalKnotError):
      discard findHobbyControls(path, path.controls)

  test "split at rough knot with diverging directions":
    let rough = nullpath().knot(p(0, 0)).curve().knot(p(1, 0)).curve().knot(p(2, 0)).finish()
    discard rough.setPreDir(1, p(1, 0))
    discard rough.setPostDir(1, p(0, 1))
    let segs = splitSegments(rough)
    check segs.len == 2
    check segs[0].start == 0
    check segs[0].`end` == 1
    check segs[1].start == 1
    check segs[1].`end` == 2

  test "mustFind propagates error":
    let path = nullpath().knot(p(0, 0)).finish()
    expect(TooFewKnotsError):
      discard mustFindHobbyControls(path, path.controls)
