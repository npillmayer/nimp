## String rendering for path snapshots/debugging.

import nimp/hobby/[builder, controls, types, utilities]

proc asString*(path: Path, ctrls: Controls = nil): string =
  var s = ""
  for i in 0 ..< path.n:
    let pt = path.z(i)
    if i > 0:
      if not ctrls.isNil:
        s &= " and " & ptString(ctrls.preControl(i), true) & "\n  .. "
      else:
        s &= " .. "
    s &= ptString(pt, false)
    if not ctrls.isNil and (i < path.n - 1 or path.isCycle):
      s &= " .. controls " & ptString(ctrls.postControl(i), true)
  if path.isCycle:
    if not ctrls.isNil:
      s &= " and " & ptString(ctrls.preControl(0), true) & "\n "
    s &= " .. cycle"
  s
