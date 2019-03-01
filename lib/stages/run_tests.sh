#!/usr/bin/env bash


_stage_run_tests() {
    printf "Running tests\n\n"

    local test_selection=""
    local docroot=$(get_distribution_docroot)
    local composer_bin_dir=$(get_composer_bin_directory)
    local project_type_directory=$(get_project_type_directory)
    local phpunit=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/phpunit
    local runtests=${docroot}/core/scripts/run-tests.sh
    local settings_file=${docroot}/sites/default/settings.php
    local test_location=${DRUPAL_TRAVIS_TEST_LOCATION:-${project_type_directory}/contrib/${DRUPAL_TRAVIS_PROJECT_NAME}}
    local project_test_directory=${docroot}/${test_location}

    case ${DRUPAL_TRAVIS_TEST_RUNNER} in
        "phpunit")
            if [ ${DRUPAL_TRAVIS_TEST_GROUP} ]; then
               test_selection="--group ${DRUPAL_TRAVIS_TEST_GROUP}"
            fi
            php ${phpunit} --verbose --debug --configuration ${docroot}/core ${test_selection} ${project_test_directory} || exit 1
        ;;
        "run-tests")
            if [ ${DRUPAL_TRAVIS_TEST_GROUP} ]; then
               test_selection="${DRUPAL_TRAVIS_TEST_GROUP}"
            else
               test_selection="--directory ${project_test_directory}"
            fi

            php ${runtests} --php $(which php) --suppress-deprecations --verbose --color --url http://${DRUPAL_TRAVIS_HTTP_HOST}:${DRUPAL_TRAVIS_HTTP_PORT} ${test_selection} || exit 1
        ;;
    esac

}
