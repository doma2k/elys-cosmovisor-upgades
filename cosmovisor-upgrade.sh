#!/bin/bash

# Elys-Network Automation Script
# This script was created to automate voting and upgrade for Elys-Network.
# It checks if the latest proposal is upgrade-related and has VOTING_PERIOD status.
# If yes, it votes for this proposal and saves its id to a file (this part is temporary till I test the API option).
# Then it scrapes the binary version from the proposal "Plan" object and builds it. (also considering to download binary using proposal info instead of building)
# Creates a related folder in .elsy/cosmovisor and copies the new binary.

# Configuration
RPC_URL="http://127.0.0.1:46018" # RPC URL
API_URL="https://api.testnet.elys.network" # API URL
USER="11111" # User ID
PASSWORD="111111111"
VOTED_PROPOSALS_FILE="$HOME/voted_proposals.txt"
GITHUB_REPO="elys-network/elys"
UPGRADES_PATH="$HOME/.elys/cosmovisor/upgrades"  # Use $HOME for the home directory 
BINARY_NAME="elysd" 
ELYSD_DIRECTORY="$HOME/elys"  # Use $HOME for the home directory

check_and_vote_proposal() {
    local ID
    local TYPE
    local STATUS
    local result=1  # Default to 1 (failure)

    # Check if the proposal ID is in the user's record of voted proposals
    if grep -Fxq "$ID" "$VOTED_PROPOSALS_FILE"; then
        echo "You have already voted on this proposal."
    else
        local proposal_info
        proposal_info=$(curl -X GET "$API_URL/cosmos/gov/v1/proposals?proposal_status=PROPOSAL_STATUS_UNSPECIFIED&pagination.count_total=true" -H "accept: application/json")

        TYPE=$(echo "$proposal_info" | jq -r '.proposal[-1].messages[0].content."@type"')
        STATUS=$(echo "$proposal_info" | jq -r '.proposal[-1].status')
        ID=$(echo "$proposal_info" | jq -r '.proposal[-1].id')

        if [ "${TYPE}" == "/cosmos.upgrade.v1beta1.SoftwareUpgradeProposal" ] && [ "${STATUS}" == "PROPOSAL_STATUS_VOTING_PERIOD" ]; then
            $BINARY_NAME tx gov vote "$ID" yes --from "$USER" --node "$RPC_URL" -y
            if [ $? -eq 0 ]; then
                echo "Successfully voted on proposal $ID."
                if [ ! -f "$VOTED_PROPOSALS_FILE" ]; then
                    touch "$VOTED_PROPOSALS_FILE"
                    echo "$VOTED_PROPOSALS_FILE created"
                fi
                echo "$ID" >> "$VOTED_PROPOSALS_FILE"
                result=0  # Set result to 0 (success) on successful vote
            else
                echo "Error occurred while voting on proposal $ID."
            fi
        else
            echo "No active proposals or the proposal does not meet the criteria."
        fi
    fi
    sleep 2
    return $result  # Return the result (0 for success, 1 for failure)
}


get_latest_release() {
    local version
    version=$(curl -X GET "$API_URL/cosmos/gov/v1/proposals?proposal_status=PROPOSAL_STATUS_UNSPECIFIED&pagination.count_total=true" -H "accept: application/json" | jq '.proposals[-1].messages[0].content' | jq .plan.name)
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

    if [ -z "$version" ] || [ "$version" == "null" ]; then
        echo "No valid version found. Skipping the build."
        exit 1
    fi

    download_repository_if_not_exists

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
        exit 1
    fi
}

main() {
    if check_and_vote_proposal; then
        # Check if a successful vote occurred
        local version
        version=$(get_latest_release)
        directories=("$UPGRADES_PATH"/*)

        if ! [[ " ${directories[@]} " =~ " $UPGRADES_PATH/$version " ]]; then
            new_version_path=$(create_directory_for_version "$version")
            build_new_version "$version" "$new_version_path"
            echo "New version initiated: $version"

        else
            echo "No new version found or already exists"
        fi
    else
        echo "Nothing to upgrade, going to sleep."
        echo '      _____|~~\_____      _____________'
        echo '  _-~               \    |    \'
        echo '  _-    | )     \    |__/   \   \'
        echo '  _-         )   |   |  |     \  \'
        echo '  _-    | )     /    |--|      |  |'
        echo ' __-_______________ /__/_______|  |_________'
        echo '(                |----         |  |'
        echo ' `---------------'\''--\\\\      .`--'\'''
        echo '                              `||||'

    fi
}

main
