#!/usr/bin/env bash

_stage_prepare_build() {
    # When we test a full project, all we need is the project files itself.
    if [[ ${DRUPAL_TRAVIS_PROJECT_TYPE} = "project" ]]; then
        rsync --archive --exclude=".git" ${DRUPAL_TRAVIS_PROJECT_BASEDIR}/ ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
        return
    fi

    printf "Prepare composer.json\n\n"

    # Build is based on drupal project
    composer create-project ${DRUPAL_TRAVIS_COMPOSER_PROJECT} ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY} --stability dev --no-interaction --no-install

    # Add asset-packagist for projects, that require frontend assets
    if ! composer_repository_exists "https://asset-packagist.org"; then
        composer config repositories.assets composer https://asset-packagist.org --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    fi

    # Require the specific Drupal core version we need, as well as the corresponding dev-requirements
    if [[ ${DRUPAL_TRAVIS_DRUPAL_VERSION} ]]; then
      composer require drupal/core-recommended:${DRUPAL_TRAVIS_DRUPAL_VERSION} --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
      composer require drupal/core-dev:${DRUPAL_TRAVIS_DRUPAL_VERSION} --dev --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    fi

    composer require drush/drush --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    # Install without core-composer-scaffold until we know, what version of core is used.
    composer remove drupal/core-composer-scaffold --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    # Require phpstan.
    if ${DRUPAL_TRAVIS_TEST_DEPRECATION}; then
        composer require mglaman/phpstan-drupal:~0.12.0 --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
        composer require phpstan/phpstan-deprecation-rules:~0.12.0 --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    fi

    # Add the local instance of the project into the repositories section.
    composer config repositories.project path ${DRUPAL_TRAVIS_PROJECT_BASEDIR} --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    # Enable patching
    composer config extra.enable-patching true --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    # require the project, we want to test.
    composer require "${DRUPAL_TRAVIS_COMPOSER_NAME}:*" --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    # Use jq to find all dev dependencies of the project and add them to root composer file.
    for dev_dependency in $(jq -r  '.["require-dev"?] | keys[] as $k | "\($k):\(.[$k])"' ${DRUPAL_TRAVIS_PROJECT_BASEDIR}/composer.json); do
        composer require ${dev_dependency} --dev --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    done
}
