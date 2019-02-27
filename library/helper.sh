#!/usr/bin/env bash


### Helper functions ###


function port_is_open() {
	local host=${1}
	local port=${2}

    $(nc -z "${host}" "${port}")
}

function wait_for_port() {
	local host=${1}
	local port=${2}
	local max_count=${3:-10}

	local count=1

	until port_is_open ${host} ${port}; do
		sleep 1
		if [ ${count} -gt ${max_count} ]
		then
			printf "Error: Timeout while waiting for port ${port} on host ${host}.\n" 1>&2
			exit 1
		fi
		count=$[count+1]
	done
}

# Test docker container health status
function get_container_health {
    docker inspect --format "{{json .State.Health.Status }}" $1
}

# Wait till docker container is fully started
function wait_for_container {
    local container=${1}
    printf "Waiting for container ${container}."
    while local status=$(get_container_health ${container}); [ ${status} != "\"healthy\"" ]; do
        if [ ${status} == "\"unhealthy\"" ]; then
            printf "Container ${container} failed to start. \n"
            exit 1
        fi
        printf "."
        sleep 1
    done
    printf " Container started!\n"
}

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