import type { Config } from "@jest/types"

const config: Config.InitialOptions = {
    preset: "ts-jest",
    testEnvironment: "node",
    verbose: true,
    automock: false,
    clearMocks: true,
    collectCoverage: true,
    coverageDirectory: "coverage",
    coverageProvider: "v8",
    testRegex: "^((?!integration).)*\\.test\\.ts$"
}

export default config
