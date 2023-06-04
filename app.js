const axios = require('axios');
const fs = require('fs');
const { execSync } = require('child_process');
const config = require('./config');

async function getLatestRelease() {
    try {
        const response = await axios.get(`https://api.github.com/repos/${config.GITHUB_REPO}/releases`);
        const version = response.data[0];
        console.log('Latest binary:', version.tag_name);
        return version.tag_name;
    } catch (error) {
        console.error("Error fetching latest release:", error);
        process.exit(1); 
    }
}

function createDirectoryForVersion(version) {
    const newVersionPath = `${config.UPGRADES_PATH}/${version}/bin/`;
    fs.mkdirSync(newVersionPath, { recursive: true });
    console.log(`Created new directory: ${newVersionPath}`);
    return newVersionPath;
}

function buildNewVersion(version, newVersionPath) {
    try {
        console.log("Building new version...");
        execSync(`cd ${process.env.HOME}/elys && git clean -fd && git reset --hard && git fetch --all && git checkout ${version} && make install && mv ${process.env.HOME}/go/bin/${config.BINARY_NAME} ${newVersionPath}`, { stdio: 'inherit' });
        console.log("Build complete.");
    } catch (error) {
        console.error("Error during build:", error);
    }
}

async function main() {
    const version = await getLatestRelease();
    const directories = fs.readdirSync(config.UPGRADES_PATH);

    if (!directories.includes(version)) {
        console.log(`New version found: ${version}`);
        const newVersionPath = createDirectoryForVersion(version);
        buildNewVersion(version, newVersionPath);
    } else {
        console.log("No new version found.");
    }
}

main();