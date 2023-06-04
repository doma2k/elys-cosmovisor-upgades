const axios = require('axios');
const fs = require('fs');
const download = require('download');
const extract = require('extract-tar');
const { execSync } = require('child_process');

const GITHUB_REPO = 'elys-network/elys';
const ELYS_UPGRADES = `${process.env.HOME}/.elys/cosmovisor/upgrades`;

async function getLatestRelease() {
    const response = await axios.get(`https://api.github.com/repos/${GITHUB_REPO}/releases`);
    const version = response.data[0];
    console.log(version.tag_name);
    return version.tag_name;
}

async function main() {
    const version = await getLatestRelease();

    const directories = fs.readdirSync(ELYS_UPGRADES);
    if (!directories.includes(version)) {
        console.log(`New version found: ${version}`);
        // Your process to download and compile the new version here...
    } else {
        console.log("No new version found.");
    }
}

main()

// async function downloadAndExtract(url, version) {
//     await download(url, '.', { filename: `${version}.tar.gz` });
//     await extract({ file: `${version}.tar.gz`, cwd: '.' });
// }

// function compileCode() {
//     // replace this command with your build commands
//     let commands = [
//         'cd project_directory',
//         'make'
//     ];

//     commands.forEach((command) => {
//         execSync(command, { stdio: 'inherit' });
//     });
// }

// async function main() {
//     const release = await getLatestRelease();
//     const version = release.tag_name;
//     const tarballUrl = release.tarball_url;

//     if (!fs.existsSync(`./${version}`)) {
//         console.log(`New version found: ${version}. Downloading and extracting...`);
//         await downloadAndExtract(tarballUrl, version);
//         console.log("Compiling new version...");
//         compileCode();
//     } else {
//         console.log("No new version found.");
//     }
// }

// main();
