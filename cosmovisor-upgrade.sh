#!/bin/bash

# Configuration
GITHUB_REPO="elys-network/elys"
UPGRADES_PATH="/path/to/your/upgrades"
BINARY_NAME="elysd"

get_latest_release() {
    local version
    version=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases" | jq -r '.[0].tag_name')
    echo "Latest binary: $version"
    echo "$version"
}

create_directory_for_version() {
    local version="$1"
    local new_version_path="$UPGRADES_PATH/$version/bin"
    mkdir -p "$new_version_path"
    echo "Created new directory: $new_version_path"
    echo "$new_version_path"
}

build_new_version() {
    local version="$1"
    local new_version_path="$2"
    echo "Building new version..."
    (
        cd /root/elys || exit 1
        git clean -fd
        git reset --hard
        git fetch --all
        git checkout "$version"
        make install
        mv /root/go/bin/"$BINARY_NAME" "$new_version_path"
    ) &> build.log
    if [ $? -eq 0 ]; then
        echo "Build complete"
    else
        echo "Error during build:"
        cat build.log
    fi
}

main() {
    local version
    version=$(get_latest_release)
    directories=("$UPGRADES_PATH"/*)

    if ! [[ " ${directories[@]} " =~ " $UPGRADES_PATH/$version " ]]; then
        echo "New version found: $version"
        new_version_path=$(create_directory_for_version "$version")
        build_new_version "$version" "$new_version_path"
    else
        echo "No new version found."
    fi
}

main
