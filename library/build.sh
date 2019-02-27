#!/usr/bin/env bash

require_local_project() {
    local dev_dependency

    composer config repositories.0 path ${DRUPAL_TRAVIS_PROJECT_BASEDIR} --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    composer config repositories.1 composer https://packages.drupal.org/8 --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    composer config extra.enable-patching true --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    composer require ${DRUPAL_TRAVIS_COMPOSER_NAME} *@dev --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    # Use jq to find all dev dependencies of the project and add them to root composer file.
    for dev_dependency in $(jq -r  '.["require-dev"?] | keys[] as $k | "\($k):\(.[$k])"' ${DRUPAL_TRAVIS_PROJECT_BASEDIR}/composer.json); do
        composer require $dev_dependency --dev --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    done
}

composer_install() {
    COMPOSER_MEMORY_LIMIT=-1 composer install --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    composer drupal:scaffold --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
}

create_drupal_project() {
    composer create-project drupal-composer/drupal-project:8.x-dev ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY} --stability dev --no-interaction --no-install
    composer config repositories.assets composer https://asset-packagist.org --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    composer require drupal/core:${DRUPAL_TRAVIS_DRUPAL_VERSION} --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
}

move_assets() {
    local libraries=$(get_distribution_docroot)/libraries;
    mkdir ${libraries}

    if [ -d ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/bower-asset ]; then
        mv ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/bower-asset/* ${libraries}
    fi
    if [ -d ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/npm-asset ]; then
        mv ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/npm-asset/* ${libraries}
    fi
}

clean_up() {
    if ${DRUPAL_TRAVIS_NO_CLEANUP}; then
        return
    fi

    docker rm -f -v selenium-for-tests

    chmod -R u+w ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    rm -rf ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    rm -rf ${DRUPAL_TRAVIS_LOCK_FILES_DIRECTORY}
    rmdir ${DRUPAL_TRAVIS_TEST_BASE_DIRECTORY}
}
