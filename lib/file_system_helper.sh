#!/usr/bin/env bash

# This has currently no real meaning, but will be necessary, once we test with thunder_project.
# thunder_project builds into docroot instead of web.
get_distribution_docroot() {
    local docroot="web"

    if [[ ${DRUPAL_TRAVIS_DISTRIBUTION} = "thunder" ]]; then
        docroot="docroot"
    fi

    echo "${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${docroot}"
}

get_composer_bin_directory() {
    if [[ ! -f ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/composer.json ]]; then
        exit 1
    fi

    local composer_bin_dir=${DRUPAL_TRAVIS_COMPOSER_BIN_DIR:-$(jq -er '.config."bin-dir" // "vendor/bin"' ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/composer.json)}

    echo "${composer_bin_dir}"
}

get_project_type_directory() {
    local project_type_directory=""
    case ${DRUPAL_TRAVIS_PROJECT_TYPE} in
        drupal-module)
            project_type_directory="modules"
            ;;
        drupal-profile)
            project_type_directory="profiles"
            ;;
        drupal-theme)
            project_type_directory="themes"
            ;;
    esac

    echo "${project_type_directory}"
}
