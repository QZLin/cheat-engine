import { existsSync, appendFileSync } from "node:fs";
import UserAgent from "https://cdn.jsdelivr.net/npm/user-agents/+esm";

const ua = new UserAgent({ deviceCategory: "desktop", platform: "Win32" }).toString();
if (existsSync(process.env.GITHUB_OUTPUT))
  appendFileSync(process.env.GITHUB_OUTPUT, `\nua=${ua}`);
