#!/usr/bin/env bash

_stage_prepare_build() {
    # When we test a full project, all we need is the project files itself.
    if [[ ${DRUPAL_TRAVIS_PROJECT_TYPE} = "project" ]]; then
        rsync --archive --exclude=".git" ${DRUPAL_TRAVIS_PROJECT_BASEDIR}/ ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
        return
    fi

    printf "Prepare composer.json\n\n"

    # Build is based on drupal project
    composer create-project drupal/recommended-project ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY} --stability dev --no-interaction --no-install

    # Add asset-packagist for projects, that require frontend assets
    composer config repositories.assets composer https://asset-packagist.org --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    # Require the specific Drupal core version we need, as well as the corresponding dev-requirements
    composer require drupal/core-recommended:${DRUPAL_TRAVIS_DRUPAL_VERSION} --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    composer require drush/drush --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    composer require drupal/core-dev:${DRUPAL_TRAVIS_DRUPAL_VERSION} --dev --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    # Install without core-composer-scaffold until we know, what version of core is used.
    composer remove drupal/core-composer-scaffold --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    # Require phpstan.
    if ${DRUPAL_TRAVIS_TEST_DEPRECATION}; then
        composer require phpstan/phpstan:0.11.6 --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
        composer require mglaman/phpstan-drupal:^0.11.1 --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
        composer require phpstan/phpstan-deprecation-rules:0.11.1 --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    fi

    # Add the local instance of the project into the repositories section and make sure it is used first.
    composer config repositories.0 path ${DRUPAL_TRAVIS_PROJECT_BASEDIR} --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    composer config repositories.1 composer https://packages.drupal.org/8 --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    # Enable patching
    composer config extra.enable-patching true --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    # require the project, we want to test.
    composer require ${DRUPAL_TRAVIS_COMPOSER_NAME} *@dev --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    # Use jq to find all dev dependencies of the project and add them to root composer file.
    for dev_dependency in $(jq -r  '.["require-dev"?] | keys[] as $k | "\($k):\(.[$k])"' ${DRUPAL_TRAVIS_PROJECT_BASEDIR}/composer.json); do
        composer require ${dev_dependency} --dev --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    done
}
