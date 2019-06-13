#!/usr/bin/env bash

_stage_install() {
    printf "Installing project\n\n"

    local docroot=$(get_distribution_docroot)
    local composer_bin_dir=$(get_composer_bin_directory)
    local drush="${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/drush  --root=${docroot}}"

    PHP_OPTIONS="-d sendmail_path=$(which true)"

    if ${DRUPAL_TRAVIS_INSTALL_FROM_CONFIG} = true; then
        ${drush} --verbose --db-url=${SIMPLETEST_DB} --yes --existing-config site-install
    else
        ${drush} --verbose --db-url=${SIMPLETEST_DB} --yes site-install ${DRUPAL_TRAVIS_TEST_PROFILE}
    fi

    ${drush} pm-enable simpletest
}
