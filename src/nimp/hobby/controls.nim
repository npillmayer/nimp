## Control point container operations.

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

proc setPreControl*(ctrls: Controls, i: int, c: Pair) =
  ctrls.pre.extendPair(i, nanPair())
  ctrls.pre[i] = c

proc setPostControl*(ctrls: Controls, i: int, c: Pair) =
  ctrls.post.extendPair(i, nanPair())
  ctrls.post[i] = c

proc preControl*(ctrls: Controls, i: int): Pair =
  getPair(ctrls.pre, i, nanPair())

proc postControl*(ctrls: Controls, i: int): Pair =
  getPair(ctrls.post, i, nanPair())
