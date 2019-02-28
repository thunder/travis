#!/usr/bin/env bash

_stage_clean_up() {
    if ${DRUPAL_TRAVIS_NO_CLEANUP}; then
        return
    fi

    if container_exists ${DRUPAL_TRAVIS_SELENIUM_DOCKER_NAME}; then
        docker rm -f -v ${DRUPAL_TRAVIS_SELENIUM_DOCKER_NAME}
    fi

    if container_exists ${DRUPAL_TRAVIS_DATABASE_DOCKER_NAME}; then
        docker rm -f -v ${DRUPAL_TRAVIS_DATABASE_DOCKER_NAME}
    fi

    chmod -R u+w ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    rm -rf ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    rm -rf ${DRUPAL_TRAVIS_LOCK_FILES_DIRECTORY}

    rmdir ${DRUPAL_TRAVIS_TEST_BASE_DIRECTORY}
}
