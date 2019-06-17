#!/usr/bin/env bash

_stage_install() {
    printf "Installing project\n\n"

    local docroot=$(get_distribution_docroot)
    local composer_bin_dir=$(get_composer_bin_directory)
    local drush="${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/drush  --root=${docroot}}"
    local drush_install_options="--verbose --db-url=${SIMPLETEST_DB} --yes"

    PHP_OPTIONS="-d sendmail_path=$(which true)"

    if ${DRUPAL_TRAVIS_INSTALL_FROM_CONFIG} = true; then
        ${drush} ${drush_install_options} --existing-config site-install
    else
        if [[ ${DRUPAL_TRAVIS_TEST_PROFILE} = "thunder" ]]; then
            local installation_form_values="${installation_form_values} thunder_module_configure_form.install_modules_thunder_demo=NULL"
        fi
        ${drush} ${drush_install_options} site-install ${DRUPAL_TRAVIS_TEST_PROFILE} ${installation_form_values}
    fi

    ${drush} pm-enable simpletest

    # Export database to speed up tests. This is currently only used by Thunder tests.
    if [[ ${DRUPAL_TRAVIS_TEST_PROFILE} = "thunder" ]]; then
        php ${docroot}/core/scripts/db-tools.php dump-database-d8-mysql > ${docroot}/database-dump.php
    fi
}
