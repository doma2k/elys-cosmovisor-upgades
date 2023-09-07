#!/bin/bash

# Configuration
GITHUB_REPO="elys-network/elys"
UPGRADES_PATH="$HOME/path/to/your/upgrades"  # Use $HOME for the home directory
BINARY_NAME="elysd"
ELYSD_DIRECTORY="$HOME/elys"  # Use $HOME for the home directory

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

download_repository_if_not_exists() {
    if [ ! -d "$ELYSD_DIRECTORY" ]; then
        echo "Downloading Elysd repository..."
        git clone "https://github.com/$GITHUB_REPO.git" "$ELYSD_DIRECTORY"
    else
        echo "Elysd repository already exists."
    fi
}

build_new_version() {
    local version="$1"
    local new_version_path="$2"
    echo "Building new version..."
    (
        cd "$ELYSD_DIRECTORY" || exit 1
        git clean -fd
        git reset --hard
        git fetch --all
        git checkout "$version"
        make install
        mv "$HOME/go/bin/$BINARY_NAME" "$new_version_path"  # Use $HOME for the home directory
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

    download_repository_if_not_exists

    if ! [[ " ${directories[@]} " =~ " $UPGRADES_PATH/$version " ]]; then
        echo "New version found: $version"
        new_version_path=$(create_directory_for_version "$version")
        build_new_version "$version" "$new_version_path"
    else
        echo "No new version found."
    fi
}

main
