#!/bin/bash

MAX_RETRIES=0
RETRY_INTERVAL=5

get_exited_containers() {
    docker ps -a --filter status=exited --format '{{.Names}}'
}

is_container_running() {
    docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null
}

is_container_healthy() {
    docker inspect -f '{{.State.Health.Status}}' "$1" 2>/dev/null
}

get_exit_code() {
    docker inspect -f '{{.State.ExitCode}}' "$1" 2>/dev/null
}

start_container() {
    docker start "$1" >/dev/null 2>&1
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
            echo "Attempting to start container $container..."

            retry_count=0
            while [[ $retry_count -lt $MAX_RETRIES || $MAX_RETRIES -eq 0 ]]; do
                start_container "$container"
                sleep $RETRY_INTERVAL
                if is_container_running "$container" && [ "$(is_container_healthy "$container")" == "healthy" ]; then
                    echo "Container $container is now running and healthy."
                    break
                elif [ $retry_count -eq $((MAX_RETRIES - 1)) ]; then
                    echo "Max retries reached for container $container. Failed to start or become healthy."
                fi
                retry_count=$((retry_count + 1))
            done

            if [[ $retry_count -eq $MAX_RETRIES ]]; then
                echo "Max retries reached for container $container. Failed to start."
            fi
        fi
    done
}

main
