const { get: _get } = require("https");

get(`https://cheatengine.org/downloads.php`, (res) => {
  let resp = "";
  res.on("data", (chunk) => {
    resp += chunk;
  });
  res.on("end", () => {
    console.log(resp.match(/download_link.*?href="(?<url>[^"]+)/).groups.url);
  });
});

/**
 * @param {string} url
 * @param {(res: import("http").IncomingMessage) => void} callback
 */
function get(url, callback) {
  _get(url, (res) => {
    if (res.statusCode === 301 || res.statusCode === 302 || res.statusCode === 307 || res.statusCode === 308) {
      get(res.headers.location, callback);
    } else {
      callback(res);
    }
  });
}
