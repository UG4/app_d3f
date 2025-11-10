#!/usr/bin/env bats

load $UG4_ROOT/apps/app_d3f_plusplus/tests/common.bash

@test "henry basic" {
    ug-run "$BATS_DIR/../henry.lua"
    check-vtu "$BATS_DIR/expected/henry" "$RUN_DIR" 0.01 0.01
}

@test "henry 3d" {
    ug-run "$BATS_DIR/../henry3d.lua"
    check-vtu "$BATS_DIR/expected/henry3d" "$RUN_DIR" 0.01 0.01
}

# @test "henry convergence" {
#    ug-run "$BATS_DIR/../conv_check_henry.lua"
# }
