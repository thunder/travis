#!/usr/bin/env bash

# Build the project
_stage_build() {
    printf "Building the project.\n\n"

    local docroot=$(get_distribution_docroot)
    local libraries=${docroot}/libraries;

    # Install all dependencies
    cd ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    COMPOSER_MEMORY_LIMIT=-1 composer install

    local installed_version=$(composer show 'drupal/core' | grep 'versions' | grep -o -E '[^ ]+$')
    local major_version="$(cut -d'.' -f1 <<<"${installed_version}")"
    local minor_version="$(cut -d'.' -f2 <<<"${installed_version}")"

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
    echo "\$settings['config_sync_directory'] = '${DRUPAL_TRAVIS_CONFIG_SYNC_DIRECTORY}';" >> ${sites_directory}/settings.php
}
