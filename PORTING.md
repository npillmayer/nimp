# nimp Porting Plan

This repository is the Nim port target for Go module `arithm`.

## Conventions
- Prefer Nim-idiomatic naming (types in `UpperCamelCase`, procs in `lowerCamelCase`).
- Keep deterministic iteration/output where Go behavior depended on sorted map traversal.
- Prefer pure/immutable-return style where practical.

## Current Status (2026-02-22)
### Completed
1. Step 1: Polynomial core (`polyn/polyn.go`) ported.
2. Step 2: Linear equation solver (`polyn/lineq.go`) ported.
3. Step 3: Hobby data model + builder API (`jhobby` builder concerns) ported.
4. Step 4: Hobby solving pipeline (validation, segmentation, open/cycle solve, controls) ported.

### Module Inventory
- Pair/numeric core:
  - `/Users/npi/prg/go/nimp/src/nimp/pair.nim`
- Linear equation stack:
  - `/Users/npi/prg/go/nimp/src/nimp/lineq/polynomial.nim`
  - `/Users/npi/prg/go/nimp/src/nimp/lineq/solver.nim`
  - `/Users/npi/prg/go/nimp/src/nimp/lineq.nim`
- Hobby stack:
  - `/Users/npi/prg/go/nimp/src/nimp/hobby/types.nim`
  - `/Users/npi/prg/go/nimp/src/nimp/hobby/controls.nim`
  - `/Users/npi/prg/go/nimp/src/nimp/hobby/builder.nim`
  - `/Users/npi/prg/go/nimp/src/nimp/hobby/utilities.nim`
  - `/Users/npi/prg/go/nimp/src/nimp/hobby/segments.nim`
  - `/Users/npi/prg/go/nimp/src/nimp/hobby/solver.nim`
  - `/Users/npi/prg/go/nimp/src/nimp/hobby/render.nim`
  - `/Users/npi/prg/go/nimp/src/nimp/hobby.nim`
- Aggregated exports:
  - `/Users/npi/prg/go/nimp/src/nimp/common.nim`
  - `/Users/npi/prg/go/nimp/src/nimp.nim`

## Test Coverage Inventory
- `/Users/npi/prg/go/nimp/tests/test.nim`
- `/Users/npi/prg/go/nimp/tests/test_pair.nim`
- `/Users/npi/prg/go/nimp/tests/test_polynomial.nim`
- `/Users/npi/prg/go/nimp/tests/test_lineq.nim`
- `/Users/npi/prg/go/nimp/tests/test_hobby_builder.nim`
- `/Users/npi/prg/go/nimp/tests/test_hobby_solver.nim`
- `/Users/npi/prg/go/nimp/tests/test_integration_lineq_hobby.nim`

All suites above currently compile and pass.

## Run Commands
From `/Users/npi/prg/go/arithm`:
- `nim c -r --nimcache:/tmp/nimcache-nimp-test1 -o:/tmp/nimp-test1 --path:../nimp/src ../nimp/tests/test.nim`
- `nim c -r --nimcache:/tmp/nimcache-nimp-test2 -o:/tmp/nimp-test2 --path:../nimp/src ../nimp/tests/test_pair.nim`
- `nim c -r --nimcache:/tmp/nimcache-nimp-test3 -o:/tmp/nimp-test3 --path:../nimp/src ../nimp/tests/test_polynomial.nim`
- `nim c -r --nimcache:/tmp/nimcache-nimp-test4 -o:/tmp/nimp-test4 --path:../nimp/src ../nimp/tests/test_lineq.nim`
- `nim c -r --nimcache:/tmp/nimcache-nimp-test5 -o:/tmp/nimp-test5 --path:../nimp/src ../nimp/tests/test_hobby_builder.nim`
- `nim c -r --nimcache:/tmp/nimcache-nimp-test6 -o:/tmp/nimp-test6 --path:../nimp/src ../nimp/tests/test_hobby_solver.nim`
- `nim c -r --nimcache:/tmp/nimcache-nimp-test7 -o:/tmp/nimp-test7 --path:../nimp/src ../nimp/tests/test_integration_lineq_hobby.nim`

## Remaining Work
1. Expand parity coverage vs Go edge cases (especially solver corner-cases and numeric drift scenarios).
2. Decide final API stabilization points (naming, exception taxonomy, mutability guarantees).
3. Add integration examples for combined `lineq` + `hobby` usage.
4. Optional: benchmarks/perf pass for larger equation/path workloads.
5. Optional: documentation polish (package-level docs and migration notes from Go API).

## Parity Strategy
- Keep Go snapshot vectors as baseline checks where possible.
- Use epsilon-based numeric assertions (`1e-7` to `1e-4`, function-dependent).
- Preserve deterministic behavior for any map-like iteration visible in output/tests.
