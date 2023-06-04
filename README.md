Elys Cosmovisor Upgrades
The elys-cosmovisor-upgrades is a Node.js application that compares the latest binary version of Elys network to the existing upgrades in the Cosmovisor folder. If the latest binary is not found, it creates a new Cosmovisor upgrade folder and builds a new binary.

NOTE: This script is designed to handle the most recent upgrades. If two or more upgrades are missing, it might not work as expected.

Requirements
Node.js
Git
make utility
A cloned repository of Elys network
Usage
To use elys-cosmovisor-upgrades, download this script to the Elys network folder and launch it from there.

Configuration
You can adjust the config.js file to make the script work with other blockchain networks. Here are the details of the configuration options:

GITHUB_REPO: The GitHub repository of the blockchain network. The default is elys-network/elys.
UPGRADES_PATH: The path to the upgrades folder. The default is ${process.env.HOME}/.elys/cosmovisor/upgrades.
BINARY_NAME: The name of the binary file. The default is elysd.
How it Works
The script performs the following steps:

Fetches the latest release from the GitHub repository.
Checks the upgrades directory to see if this version already exists.
If the version does not exist, it creates a new directory for this version in the upgrades folder.
It then cleans the Git repository, checks out the correct version, builds the project, and moves the binary file to the new upgrade directory.
Contributing
Contributions to elys-cosmovisor-upgrades are welcome. Please submit a pull request or create an issue for any bugs or feature requests.

License
elys-cosmovisor-upgrades is released under the MIT License.