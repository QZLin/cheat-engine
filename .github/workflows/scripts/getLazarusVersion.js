const { readFileSync } = require("fs");
const { join } = require("path");

let fileContent = readFileSync(join(process.env.GITHUB_WORKSPACE, "README.md"), { encoding: "utf-8", flag: "r" });
let versions = fileContent.match(/lazarus-(?<lazarus>[0-9]+\.[0-9]+\.[0-9]+)-fpc-(?<fpc>[0-9]+\.[0-9]+\.[0-9]+)-cross-i386-win32-win64\.exe/);

console.log(versions.groups.lazarus);
