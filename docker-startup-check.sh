#!/bin/bash

get_exited_containers() {
    docker ps -a --filter status=exited --format '{{.Names}}'
}

get_exit_code() {
    docker inspect -f '{{.State.ExitCode}}' "$1" 2>/dev/null
}

start_container() {
    docker start "$1" >/dev/null 2>&1
    docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null
}

main() {
    containers=$(get_exited_containers)
    if [ -z "$containers" ]; then
        echo "No containers have failed to start."
        exit 0
    fi

    echo "Containers that have failed to start:"
    echo "$containers"

    for container in $containers; do
        if [ "$(get_exit_code "$container")" == "0" ]; then
            echo "Container $container exited gracefully. No action required."
        else
            echo "Attempting to start $container..."
            start_container "$container"
        fi
    done
}

main
