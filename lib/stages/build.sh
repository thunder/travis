#!/usr/bin/env bash

# Build the project
_stage_build() {
    printf "Building the project.\n\n"

    local drupal_version
    local docroot=$(get_distribution_docroot)
    local libraries=${docroot}/libraries;

    # Install all dependencies
    cd ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    COMPOSER_MEMORY_LIMIT=-1 composer install

    drupal_version=$(composer show 'drupal/core' | grep 'versions' | grep -o -E '[^ ]+$')

    echo "${drupal_version}"
    exit 1

    # Make sure, we have drupal scaffold files. Composer install should have taken care of it, but this fails for
    # Drupal version < 8.8. This should be removed, once 8.7 support is gone.
    if [[ ! -f ${docroot}/index.php ]]; then
        composer remove drupal/core-composer-scaffold --no-update
        composer require drupal-composer/drupal-scaffold
        composer drupal:scaffold
    fi

    # Back to previous directory.
    cd -

    # Move downloaded frontend libraries to the correct folder within the web root. This is necessary, because the
    # drupal project composer.json does not provide the necessary configuration to do so.
    if [[ ! -d ${libraries} ]]; then
        mkdir ${libraries}
    fi

    if [[ -d ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/bower-asset ]]; then
        mv ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/bower-asset/* ${libraries}
    fi

    if [[ -d ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/npm-asset ]]; then
        mv ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/npm-asset/* ${libraries}
    fi

    # Copy default settings and append config sync directory.
    local sites_directory="${docroot}/sites/default"
    cp "${sites_directory}/default.settings.php" "${sites_directory}/settings.php"
    echo "\$config_directories = [ CONFIG_SYNC_DIRECTORY => '${DRUPAL_TRAVIS_CONFIG_SYNC_DIRECTORY}' ];" >> ${sites_directory}/settings.php
}
