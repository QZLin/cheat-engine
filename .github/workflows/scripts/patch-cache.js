const filePath = require("path").join(__dirname, "../actions/cache/dist/restore/index.js");

require("fs").writeFileSync(
  filePath,
  require("fs")
    .readFileSync(filePath, { encoding: "utf8" })
    .replace(/(function downloadCache\(archiveLocation, archivePath, options\) {).*?(^})/ms, "$1$2")
);
