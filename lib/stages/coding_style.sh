#!/usr/bin/env bash

# Test coding styles
_stage_coding_style() {
    if ! ${DRUPAL_TRAVIS_TEST_CODING_STYLES}; then
        return
    fi

    local check_parameters=""

    if ! [ -x "$(command -v eslint)" ]; then
        npm install -g eslint
    fi

    if ${DRUPAL_TRAVIS_TEST_PHP}; then
        check_parameters="${check_parameters} --phpcs"
    fi

    if ${DRUPAL_TRAVIS_TEST_JAVASCRIPT}; then
        check_parameters="${check_parameters} --javascript"
    fi

    bash check-guidelines.sh --init
    bash check-guidelines.sh -v ${check_parameters}

    # Propagate possible errors
    local exit_code=${?}
    if [ ${exit_code} -ne 0 ]; then
        exit ${exit_code}
    fi
}
