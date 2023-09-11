#!/bin/bash

# Configuration
RPC_URL="http://127.0.0.1:11111" # RPC URL
API_URL="https://api.testnet.elys.network" # API URL
USER="111111" # User ID
PASSWORD="1111111"
VOTED_PROPOSALS_FILE="$HOME/voted_proposals.txt"
GITHUB_REPO="elys-network/elys"
UPGRADES_PATH="$HOME/.elys/cosmovisor/upgrades"  # Use $HOME for the home directory 
BINARY_NAME="elysd"
ELYSD_DIRECTORY="$HOME/elys"  # Use $HOME for the home directory

check_and_vote_proposal() {
    local proposal_id="$1"
    local type
    local id
    local status

    if [ ! -f "$VOTED_PROPOSALS_FILE" ]; then
        touch "$VOTED_PROPOSALS_FILE"
        echo "$VOTED_PROPOSALS_FILE created"
    fi

    # Check if the proposal ID is in the user's record of voted proposals
    if grep -Fxq "$proposal_id" "$VOTED_PROPOSALS_FILE"; then
        echo "You have already voted on this proposal."
    else
        local proposal_info
        proposal_info=$(curl -sX GET "$API_URL/cosmos/gov/v1/proposals/$proposal_id" -H "accept: application/json")

        type=$(echo "$proposal_info" | jq -r '.proposal.messages[0].content."@type"')
        status=$(echo "$proposal_info" | jq -r '.proposal.status')

        if [ "${type}" == "/cosmos.upgrade.v1beta1.SoftwareUpgradeProposal" ] && [ "${status}" == "PROPOSAL_STATUS_VOTING_PERIOD" ]; then
            $BINARY_NAME tx gov vote "$proposal_id" yes --from "$USER" --node "$RPC_URL" -y
            if [ $? -eq 0 ]; then
                echo "Successfully voted on proposal $proposal_id."
                echo "$proposal_id" >> "$VOTED_PROPOSALS_FILE"
            else
                echo "Error occurred while voting on proposal $proposal_id."
            fi
        else
            echo "No active proposals or the proposal does not meet the criteria."
        fi
    fi
    sleep 2
}

get_latest_release() {
    local version
    version=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases" | jq -r '.[0].tag_name')
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
        cp "$HOME/go/bin/$BINARY_NAME" "$new_version_path"  # Use $HOME for the home directory
    ) &> build.log
    if [ $? -eq 0 ]; then
        echo "Build complete"
    else
        echo "Error during build:"
        cat build.log
    fi
}

main() {
    vote_update_proposal
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
