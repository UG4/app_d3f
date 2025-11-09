# How to write tests

This repository uses [bats](https://github.com/bats-core/bats-core) to run system tests and generate reports.

Each test must be defined in a .bats file somewhere in this repository to be eventually run by the CI runner.
Such a .bats file may include multiple tests and could look like this:
```
#!/usr/bin/env bats

load $UG4_ROOT/apps/app_d3f/tests/common.bash

@test "elder basic" {
    ug-run "$BATS_DIR/../elder.lua"
}

@test "elder smooth" {
    ug-run "$BATS_DIR/../smooth_elder.lua"
    check-vtu "$BATS_DIR/expected/smooth_elder" "$RUN_DIR" 0.01 0.01
}
```

Going over line by line:


```
#!/usr/bin/env bats
```
This is just a standard [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)) for bats.


```
load $UG4_ROOT/apps/app_d3f/tests/common.bash
```
This loads in a bash script which defines variables and helper functions. For a deeper understanding check it out!


```
@test "elder basic" {
    ug-run "$BATS_DIR/../elder.lua"
}
```
This is a simple test that executes the elder.lua script using the helper `ug-run` from common.bash.
The environment variable `$BATS_DIR` is the absolute path to the .bats file where this test is defined in.

Each test starts with a `@test` followed by a name in quotes and has a body `{...}` with a shell script to run.
Here the test is successful if the script runs through and returns 0. In case a test fails (non zero return code),
the output will be available in the generated report and a folder with artifacts will be located in `$BATS_DIR/test-artifacts/`.


```
@test "elder smooth" {
    ug-run "$BATS_DIR/../smooth_elder.lua"
    check-vtu "$BATS_DIR/expected/smooth_elder" "$RUN_DIR" 0.01 0.01
}
```
This test is similar to the previous, except that it uses the helper `check-vtu` to verify the correctness of
the generated script output. `check-vtu` takes the following 4 arguments:
1. Path to the correct .vtu files, here placed in `$BATS_DIR/expected/smooth_elder`
2. Path to the test .vtu files, by default in `$RUN_DIR` where the script is executed.
A test file is skipped if there is no matching correct file.
3. The maximum allowed absolute error.
4. The maximum allowed relative error.

It is recommended to only use a few correct files for comparison to reduce bloat.
To understand how .vtu files are compared, see the diffvtu.py script.