#!/usr/bin/env bash

TRAVIS_BUILD_DIR=${TRAVIS_BUILD_DIR:-$(pwd)}

THUNDER_TRAVIS_PROJECT_BASEDIR=${THUNDER_TRAVIS_PROJECT_BASEDIR:-${TRAVIS_BUILD_DIR}}

THUNDER_TRAVIS_DISTRIBUTION=${THUNDER_TRAVIS_DISTRIBUTION:-drupal}

THUNDER_TRAVIS_COMPOSER_NAME=${THUNDER_TRAVIS_COMPOSER_NAME:-$(jq -r .name ${THUNDER_TRAVIS_PROJECT_BASEDIR}/composer.json)}

THUNDER_TRAVIS_PROJECT_NAME=${THUNDER_TRAVIS_PROJECT_NAME-$(echo ${THUNDER_TRAVIS_COMPOSER_NAME} | cut -d '/' -f 2)}

THUNDER_TRAVIS_TEST_JAVASCRIPT=${THUNDER_TRAVIS_TEST_JAVASCRIPT:-1}

THUNDER_TRAVIS_TEST_PHP=${THUNDER_TRAVIS_TEST_PHP:-1}

THUNDER_TRAVIS_DRUPAL_VERSION=${THUNDER_TRAVIS_DRUPAL_VERSION:-^8.6}

# The version of thunder to test against, as long as drupal 8.6.0 is not released, only the 8.x-3.x dev branch is supported
THUNDER_TRAVIS_THUNDER_VERSION=${THUNDER_TRAVIS_THUNDER_VERSION:-dev-8.x-3.x}

THUNDER_TRAVIS_TEST_BASE_DIRECTORY=${THUNDER_TRAVIS_TEST_BASE_DIRECTORY:-/tmp/${THUNDER_TRAVIS_PROJECT_NAME}}

# The directory, where drupal will be installed, defaults to ${THUNDER_TRAVIS_TEST_BASE_DIRECTORY}/test-install
THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY:-${THUNDER_TRAVIS_TEST_BASE_DIRECTORY}/test-install}

THUNDER_TRAVIS_TEST_GROUP=${THUNDER_TRAVIS_TEST_GROUP-${THUNDER_TRAVIS_PROJECT_NAME}}

THUNDER_TRAVIS_TEST_CODING_STYLES=${THUNDER_TRAVIS_TEST_CODING_STYLES:-1}

THUNDER_TRAVIS_HOST=${THUNDER_TRAVIS_HOST:-127.0.0.1}

THUNDER_TRAVIS_HTTP_PORT=${THUNDER_TRAVIS_HTTP_PORT:-8888}

THUNDER_TRAVIS_SELENIUM_CHROME_VERSION=${THUNDER_TRAVIS_SELENIUM_CHROME_VERSION:-latest}

THUNDER_TRAVIS_SELENIUM_HOST=${THUNDER_TRAVIS_SELENIUM_HOST:-${THUNDER_TRAVIS_HOST}}

THUNDER_TRAVIS_SELENIUM_PORT=${THUNDER_TRAVIS_SELENIUM_PORT:-4444}

THUNDER_TRAVIS_MYSQL_HOST=${THUNDER_TRAVIS_MYSQL_HOST:-${THUNDER_TRAVIS_HOST}}

THUNDER_TRAVIS_MYSQL_PORT=${THUNDER_TRAVIS_MYSQL_PORT:-3306}

THUNDER_TRAVIS_MYSQL_USER=${THUNDER_TRAVIS_MYSQL_USER:-travis}

# The mysql password for user ${THUNDER_TRAVIS_MYSQL_USER}, empty by default.
THUNDER_TRAVIS_MYSQL_PASSWORD=${THUNDER_TRAVIS_MYSQL_PASSWORD}

THUNDER_TRAVIS_MYSQL_DATABASE=${THUNDER_TRAVIS_MYSQL_DATABASE:-drupaltesting}

THUNDER_TRAVIS_TEST_RUNNER=${THUNDER_TRAVIS_TEST_RUNNER:-phpunit}

THUNDER_TRAVIS_LOCK_FILES_DIRECTORY=${THUNDER_TRAVIS_LOCK_FILES_DIRECTORY:-${THUNDER_TRAVIS_TEST_BASE_DIRECTORY}/finished-stages}

THUNDER_TRAVIS_NO_CLEANUP=${THUNDER_TRAVIS_NO_CLEANUP}

export SYMFONY_DEPRECATIONS_HELPER=${SYMFONY_DEPRECATIONS_HELPER-weak}

export SIMPLETEST_BASE_URL=${SIMPLETEST_BASE_URL:-http://${THUNDER_TRAVIS_HOST}:${THUNDER_TRAVIS_HTTP_PORT}}

export SIMPLETEST_DB=${SIMPLETEST_DB:-mysql://${THUNDER_TRAVIS_MYSQL_USER}:${THUNDER_TRAVIS_MYSQL_PASSWORD}@${THUNDER_TRAVIS_MYSQL_HOST}:${THUNDER_TRAVIS_MYSQL_PORT}/${THUNDER_TRAVIS_MYSQL_DATABASE}}

export MINK_DRIVER_ARGS_WEBDRIVER=${MINK_DRIVER_ARGS_WEBDRIVER-"[\"chrome\", null, \"http://${THUNDER_TRAVIS_SELENIUM_HOST}:${THUNDER_TRAVIS_SELENIUM_PORT}/wd/hub\"]"}
