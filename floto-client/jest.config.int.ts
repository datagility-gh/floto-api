import config from "./jest.config";

config.testRegex = "\\.integration\\.test\\.ts$";
config.testTimeout = 120000; // 2min timeout to allow for container cold-start.

export default config;
