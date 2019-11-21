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
        local installation_directory=deprecation-check-installation

        pushd "${DRUPAL_TRAVIS_TEST_BASE_DIRECTORY}"
        composer create-project drupal-composer/drupal-project:8.x-dev "${installation_directory}" --stability dev --no-interaction --no-install

        cd "${installation_directory}" || exit

        # Add asset-packagist for projects, that require frontend assets
        composer config repositories.assets composer https://asset-packagist.org

        # Require the specific Drupal core version we need, as well as the corresponding dev-requirements
        composer require drupal/core:"${DRUPAL_TRAVIS_TEST_DEPRECATION_DRUPAL_CHECK_DRUPAL_VERSION}" --no-update
        composer require webflo/drupal-core-require-dev:"${DRUPAL_TRAVIS_TEST_DEPRECATION_DRUPAL_CHECK_DRUPAL_VERSION}" --dev --no-update

        # Add the local instance of the project into the repositories section and make sure it is used first.
        composer config repositories.0 path "${DRUPAL_TRAVIS_PROJECT_BASEDIR}"
        composer config repositories.1 composer https://packages.drupal.org/8

        # Enable patching
        composer config extra.enable-patching true

        # require the project, we want to test.
        composer require "${DRUPAL_TRAVIS_COMPOSER_NAME}" *@dev --no-update

        # Use jq to find all dev dependencies of the project and add them to root composer file.
        for dev_dependency in $(jq -r  '.["require-dev"?] | keys[] as $k | "\($k):\(.[$k])"' "${DRUPAL_TRAVIS_PROJECT_BASEDIR}"/composer.json); do
            composer require "${dev_dependency}" --dev --no-update
        done

        composer require mglaman/drupal-check --no-update

        pwd

        echo "Install drupal.ckeck instance"
        COMPOSER_MEMORY_LIMIT=-1 composer install
        vendor/bin/drupal-check web/"${project_location}"

        cd - || exit

        rm -rf "${installation_directory}"

        popd
    fi
}
