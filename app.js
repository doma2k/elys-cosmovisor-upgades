const axios = require('axios');
const fs = require('fs').promises; // Use fs.promises for async file operations
const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);
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

async function createDirectoryForVersion(version) {
    const newVersionPath = `${config.UPGRADES_PATH}/${version}/bin/`;
    try {
        await fs.mkdir(newVersionPath, { recursive: true });
        console.log(`Created new directory: ${newVersionPath}`);
        return newVersionPath;
    } catch (error) {
        console.error("Error creating directory:", error);
    }
}

async function buildNewVersion(version, newVersionPath) {
    try {
        console.log("Building new version...");
        const { stdout, stderr } = await execAsync(`cd ${process.env.HOME}/elys && git clean -fd && git reset --hard && git fetch --all && git checkout ${version} && make install && mv ${process.env.HOME}/go/bin/${config.BINARY_NAME} ${newVersionPath}`);
        console.log("Build complete:", stdout);
    } catch (error) {
        console.error("Error during build:", error.stderr);
    }
}

async function main() {
    try {
        const version = await getLatestRelease();
        const directories = await fs.readdir(config.UPGRADES_PATH);

        if (!directories.includes(version)) {
            console.log(`New version found: ${version}`);
            const newVersionPath = await createDirectoryForVersion(version);
            await buildNewVersion(version, newVersionPath);
        } else {
            console.log("No new version found.");
        }
    } catch (error) {
        console.error("An error occurred:", error);
    }
}

main();
