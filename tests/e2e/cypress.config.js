const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
    baseUrl: 'http://calc-web',
    specPattern: 'cypress/integration/**/*.js',
    supportFile: false,
  },
  reporter: 'junit',
  reporterOptions: {
    mochaFile: '/results/cypress_result.xml',
    toConsole: false,
  },
  defaultCommandTimeout: 1000,
})
