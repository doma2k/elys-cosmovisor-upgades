const axios = require('axios');
const fs = require('fs');
const { execSync } = require('child_process');

const GITHUB_REPO = 'elys-network/elys';
const UPGRADES = `${process.env.HOME}/.elys/cosmovisor/upgrades`;
const BINARY_NAME = 'elysd';

async function getLatestRelease() {
    const response = await axios.get(`https://api.github.com/repos/${GITHUB_REPO}/releases`);
    const version = response.data[0];
    console.log('Latest binary:', version.tag_name);
    return version.tag_name;
}

async function main() {

    const version = await getLatestRelease();
    const directories = fs.readdirSync(UPGRADES);

    if (!directories.includes(version)) {
        console.log(`New version found: ${version}`);

        const newVersionPath = `${UPGRADES}/${version}/bin/`;
        fs.mkdirSync(newVersionPath, { recursive: true });
        console.log(`Created new directory: ${newVersionPath}`);

        // Building the new version
        try {
            console.log("Building new version...");
            execSync(`cd ${process.env.HOME}/elys && git clean -fd && git reset --hard && git fetch --all && git checkout ${version} && make install && mv ${process.env.HOME}/go/bin/${BINARY_NAME} ${newVersionPath}`, { stdio: 'inherit' });
            console.log("Build complete.");
        } catch (error) {
            console.error("Error during build:", error);
        }
    } else {
        console.log("No new version found.");
    }
}

main();
