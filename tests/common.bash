BATS_TEST_TIMEOUT=900

setup() {
    BATS_DIR="$( dirname "$BATS_TEST_FILENAME" )"
    RUN_DIR="$BATS_DIR/test-artifacts/$BATS_TEST_NAME"

    # ensure correct directory for running tests
    mkdir -p "$RUN_DIR"
    cd $RUN_DIR && rm -rf *
}

teardown() {
    # cleanup on success only
    if [ -n "$BATS_TEST_COMPLETED" ]; then
        rm -rf "$RUN_DIR"
    fi
}

ug-run() {
    if [[ "$UG_CMAKE_PARALLEL" == "ON" ]]; then
        mpirun --allow-run-as-root -n 1 ugshell -ex $1
    else
        ugshell -ex $1
    fi
}

check-vtu() {
    readarray -d '' expected < <(find $1 -type f -name "*.vtu" -print0)
    for path in "${expected[@]}"
    do
        name=$(basename $path)
        python3 $UG4_ROOT/apps/app_d3f_plusplus/tests/diffvtu.py "$1/$name" "$2/$name" $3 $4
    done
}
