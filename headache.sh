#!/bin/bash -e

dirs=(
    # Add new directories below:
    "lib/cmdlang_cmdliner_runner/src"
    "lib/cmdlang_cmdliner_runner/test"
    "lib/pp_tty/src"
    "lib/pp_tty/test"
    "lib/log/src"
    "lib/log/test"
    "lib/err/src"
    "lib/err/test"
    "lib/err/test/cram"
    "lib/log_cli/src"
    "lib/log_cli/test"
)

for dir in "${dirs[@]}"; do
    # Apply headache to .ml files
    headache -c .headache.config -h COPYING.HEADER ${dir}/*.ml

    # Check if .mli files exist in the directory, if so apply headache
    if ls ${dir}/*.mli 1> /dev/null 2>&1; then
        headache -c .headache.config -h COPYING.HEADER ${dir}/*.mli
    fi
done

dune fmt
