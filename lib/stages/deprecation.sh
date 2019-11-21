#!/usr/bin/env bash

_stage_deprecation() {
    printf "Checking for deprecations.\n\n"

    local docroot=$(get_distribution_docroot)
    local project_location=$(get_project_location)

    if ${DRUPAL_TRAVIS_TEST_DEPRECATION_PHPSTAN}; then
        cp phpstan.neon "${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}"
        cd "${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}" || exit
        vendor/bin/phpstan analyse --memory-limit 300M "${docroot}"/"${project_location}"
        cd - || exit
    fi

    if ${DRUPAL_TRAVIS_TEST_DEPRECATION_DRUPAL_CHECK}; then
        # We need to do a new installation for the deprecation test, since we might want to test against a different
        # Drupal version.
        local installation_directory="${DRUPAL_TRAVIS_TEST_BASE_DIRECTORY}""/deprecation-check-installation"
        composer create-project drupal-composer/drupal-project:8.x-dev "${installation_directory}" --stability dev --no-interaction --no-install

        # Add asset-packagist for projects, that require frontend assets
        composer config repositories.assets composer https://asset-packagist.org --working-dir="${installation_directory}"

        # Require the specific Drupal core version we need, as well as the corresponding dev-requirements
        composer require drupal/core:"${DRUPAL_TRAVIS_TEST_DEPRECATION_DRUPAL_CHECK_DRUPAL_VERSION}" --no-update --working-dir="${installation_directory}"
        composer require webflo/drupal-core-require-dev:"${DRUPAL_TRAVIS_TEST_DEPRECATION_DRUPAL_CHECK_DRUPAL_VERSION}" --dev --no-update --working-dir="${installation_directory}"

        # Add the local instance of the project into the repositories section and make sure it is used first.
        composer config repositories.0 path "${DRUPAL_TRAVIS_PROJECT_BASEDIR}" --working-dir="${installation_directory}"
        composer config repositories.1 composer https://packages.drupal.org/8 --working-dir="${installation_directory}"

        # Enable patching
        composer config extra.enable-patching true --working-dir="${installation_directory}"

        # require the project, we want to test.
        composer require "${DRUPAL_TRAVIS_COMPOSER_NAME}" *@dev --no-update --working-dir="${installation_directory}"

        # Use jq to find all dev dependencies of the project and add them to root composer file.
        for dev_dependency in $(jq -r  '.["require-dev"?] | keys[] as $k | "\($k):\(.[$k])"' "${DRUPAL_TRAVIS_PROJECT_BASEDIR}"/composer.json); do
            composer require "${dev_dependency}" --dev --no-update --working-dir="${installation_directory}"
        done

        composer require mglaman/drupal-check --no-update --working-dir="${installation_directory}"

        cd "${installation_directory}" || exit

        COMPOSER_MEMORY_LIMIT=-1 composer install
        vendor/bin/drupal-check web/"${project_location}"

        cd - || exit

        rm -rf "${installation_directory}"
    fi
}
