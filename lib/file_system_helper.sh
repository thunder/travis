#!/usr/bin/env bash

# This has currently no real meaning, but will be necessary, once we test with thunder_project.
# thunder_project builds into docroot instead of web.
get_distribution_docroot() {
    local docroot="web"

    if [ ${DRUPAL_TRAVIS_DISTRIBUTION} = "thunder" ]; then
        docroot="docroot"
    fi

    echo ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${docroot}
}

get_composer_bin_directory() {
    if [ ! -f ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/composer.json ]; then
        exit 1
    fi

    local composer_bin_dir=${DRUPAL_TRAVIS_COMPOSER_BIN_DIR:-$(jq -er '.config."bin-dir" // "vendor/bin"' ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/composer.json)}

    echo ${composer_bin_dir}
}

get_project_type_directory() {
    if [ ! -f ${DRUPAL_TRAVIS_PROJECT_BASEDIR}/composer.json ]; then
        local project_type="drupal-module"
    else
        local project_type=$(jq -er '.type // "drupal-module"' ${DRUPAL_TRAVIS_PROJECT_BASEDIR}/composer.json)
    fi

    case ${project_type} in
        drupal-module)
            local project_type_directory="modules"
            ;;
        drupal-profile)
            local project_type_directory="profiles"
            ;;
        drupal-theme)
            local project_type_directory="themes"
            ;;
    esac

    echo "${project_type_directory}"
}
