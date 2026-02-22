## Core types and errors for Hobby paths.

import nimp/pair

type
  HobbyError* = object of CatchableError
  NilPathError* = object of HobbyError
  TooFewKnotsError* = object of HobbyError
  InvalidKnotError* = object of HobbyError
  DegenerateSegmentError* = object of HobbyError
  DuplicateCycleTerminalKnotError* = object of HobbyError

  Path* = ref object
    points*: seq[Pair]
    cycleFlag*: bool
    predirs*: seq[Pair]
    postdirs*: seq[Pair]
    curls*: seq[Pair]
    tensions*: seq[Pair]
    controls*: Controls

  Controls* = ref object
    pre*: seq[Pair]
    post*: seq[Pair]

  PathPartial* = ref object
    whole*: Path
    start*: int
    `end`*: int
    controls*: Controls

proc nanPair*(): Pair {.inline.} =
  p(NaN, NaN)

proc newControls*(): Controls =
  Controls(pre: @[], post: @[])

proc newPath*(): Path =
  Path(
    points: @[],
    cycleFlag: false,
    predirs: @[],
    postdirs: @[],
    curls: @[],
    tensions: @[],
    controls: newControls()
  )
