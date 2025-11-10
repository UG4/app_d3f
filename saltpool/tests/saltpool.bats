#!/usr/bin/env bats

SCRIPT_PATH=$(dirname "${BATS_TEST_FILENAME}")
load $SCRIPT_PATH/../../tests/common.bash

@test "Saltpool (2D)" {
    ug-run "$BATS_DIR/../saltpool.lua" --problem SALTPOOL2D
    # check-vtu "$BATS_DIR/expected/saltpool_2D" "$RUN_DIR" 0.01 0.01
}

@test "Saltpool (3D)" {
    ug-run "$BATS_DIR/../saltpool.lua" --problem SALTPOOL3D
    # check-vtu "$BATS_DIR/expected/saltpool_3D" "$RUN_DIR" 0.01 0.01
}
