#!/usr/bin/env bash

run_stage() {
    local stage="${1}"

    if stage_is_finished ${stage}; then
        return
    fi

    local dependency=$(stage_dependency ${stage})

    if [ ! -z ${dependency} ]; then
        run_stage ${dependency}
    fi

    # Call the stage function
    _stage_${stage}

    finish_stage ${stage}
}

stage_exists() {
    declare -f -F _stage_${1} > /dev/null
    return ${?}
}

stage_dependency() {
    case ${1} in
        run_tests)
            local dep="start_web_server"
            ;;
        start_web_server)
            local dep="install"
            ;;
        install)
            local dep="build"
            ;;
        build)
            local dep="prepare_build"
            ;;
        prepare_build)
            local dep="coding_style"
            ;;
        coding_style)
            local dep="setup"
            ;;
    esac

    echo "${dep}"
}

stage_is_finished() {
    [ -f "${DRUPAL_TRAVIS_LOCK_FILES_DIRECTORY}/${1}" ]
}

finish_stage() {
    local stage="${1}"

    if [ ! -d ${DRUPAL_TRAVIS_LOCK_FILES_DIRECTORY} ]; then
        mkdir -p ${DRUPAL_TRAVIS_LOCK_FILES_DIRECTORY}
    fi

    touch ${DRUPAL_TRAVIS_LOCK_FILES_DIRECTORY}/${stage}
}


### The stages. Do not run these directly, use run_stage() to invoke. ###

_stage_setup() {
    printf "Setup environment\n\n"

    if  ! port_is_open ${DRUPAL_TRAVIS_SELENIUM_HOST} ${DRUPAL_TRAVIS_SELENIUM_PORT} ; then
        printf "Starting web driver\n"
        if ${TRAVIS} = true; then
            docker run --detach --net host --name ${DRUPAL_TRAVIS_SELENIUM_DOCKER_NAME} --volume /dev/shm:/dev/shm selenium/standalone-chrome:${DRUPAL_TRAVIS_SELENIUM_CHROME_VERSION}
        else
            chromedriver --port=${DRUPAL_TRAVIS_SELENIUM_PORT} &
        fi
        wait_for_port ${DRUPAL_TRAVIS_SELENIUM_HOST} ${DRUPAL_TRAVIS_SELENIUM_PORT}
    fi

    if  ! port_is_open ${DRUPAL_TRAVIS_DATABASE_HOST} ${DRUPAL_TRAVIS_DATABASE_PORT} ; then
        printf "Starting database\n"
        # We start a docker container, they need a password set, so we set one now if none was given.
        # We do not generally provide a default password, because already running database instances might have no
        # password. This is e.g. the case for the default travis database.
        local docker_database_password=${DRUPAL_TRAVIS_DATABASE_PASSWORD:-123456}
        docker run --detach --publish ${DRUPAL_TRAVIS_DATABASE_PORT}:3306 --name ${DRUPAL_TRAVIS_DATABASE_DOCKER_NAME} --env "MYSQL_USER=${DRUPAL_TRAVIS_DATABASE_USER}" --env "MYSQL_PASSWORD=${docker_database_password}" --env "MYSQL_DATABASE=${DRUPAL_TRAVIS_DATABASE_NAME}" --env "MYSQL_ALLOW_EMPTY_PASSWORD=true" mysql/mysql-server:5.7
        wait_for_container ${DRUPAL_TRAVIS_DATABASE_DOCKER_NAME}
    fi

    if [ -x "$(command -v phpenv)" ]; then
        printf "Configure php\n"
        phpenv config-rm xdebug.ini || true
        # Needed for php 5.6 only. When we drop 5.6 support, this can be removed.
        echo 'always_populate_raw_post_data = -1' >> drupal.php.ini
        phpenv config-add drupal.php.ini
        phpenv rehash
    fi
}

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

_stage_prepare_build() {
    printf "Prepare composer.json\n\n"
    if ${TRAVIS}; then
        composer global require hirak/prestissimo
    fi

    create_drupal_project
    composer require webflo/drupal-core-require-dev:${DRUPAL_TRAVIS_DRUPAL_VERSION} --dev --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    require_local_project
}

_stage_build() {
    printf "Prepare build\n\n"
    composer_install
    move_assets
}

_stage_install() {
    printf "Installing project\n\n"

    local composer_bin_dir=$(get_composer_bin_directory)
    local drush="${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/drush  --root=$(get_distribution_docroot)"
    local profile="minimal"
    local additional_drush_parameter=""

    PHP_OPTIONS="-d sendmail_path=$(which true)"
    ${drush} site-install ${profile} -vvv --db-url=${SIMPLETEST_DB} --yes additional_drush_parameter
    ${drush} pm-enable simpletest
}

_stage_start_web_server() {
    printf "Starting web server\n\n"

    local drupal="core/scripts/drupal"
    local composer_bin_dir=$(get_composer_bin_directory)
    local docroot=$(get_distribution_docroot)
    local drush="${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/drush  --root=${docroot}"


    if  ! port_is_open ${DRUPAL_TRAVIS_HTTP_HOST} ${DRUPAL_TRAVIS_HTTP_PORT} ; then
        ${drush} runserver "http://${DRUPAL_TRAVIS_HTTP_HOST}:${DRUPAL_TRAVIS_HTTP_PORT}" >/dev/null 2>&1 &
        wait_for_port ${DRUPAL_TRAVIS_HTTP_HOST} ${DRUPAL_TRAVIS_HTTP_PORT}
    fi
}

_stage_run_tests() {
    printf "Running tests\n\n"

    local test_selection
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
