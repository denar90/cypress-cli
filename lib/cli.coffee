_         = require("lodash")
commander = require("commander")
updater   = require("update-notifier")
human     = require("human-interval")
pkg       = require("../package.json")

## check for updates every hour
updater({pkg: pkg, updateCheckInterval: human("one hour")}).notify()

coerceFalse = (arg) ->
  if arg is "false" then false else true

parseOpts = (opts) ->
  _.pick(opts, "spec", "reporter", "reporterOptions", "path", "destination", "port", "env", "cypressVersion", "config", "record", "key")

descriptions = {
  destination:     "destination path to extract and install Cypress to"
  record:          "records the run. sends test results, screenshots and videos to your Cypress Dashboard."
  key:             "your secret Record Key. you can omit this if you set a CYPRESS_RECORD_KEY environment variable."
  spec:            "runs a specific spec file. defaults to 'all'"
  reporter:        "runs a specific mocha reporter. pass a path to use a custom reporter. defaults to 'spec'"
  reporterOptions: "options for the mocha reporter. defaults to 'null'"
  port:            "runs Cypress on a specific port. overrides any value in cypress.json. defaults to '2020'"
  env:             "sets environment variables. separate multiple values with a comma. overrides any value in cypress.json or cypress.env.json"
  config:          "sets configuration values. separate multiple values with a comma. overrides any value in cypress.json."
  version:         "installs a specific version of Cypress"
}

text = (d) ->
  descriptions[d] ? throw new Error("Could not find description for: #{d}")

module.exports = ->
  ## instantiate a new program for
  ## easier testability
  program = new commander.Command()

  exit = ->
    process.exit(0)

  displayVersion = ->
    require("./commands/version")()
    .then(exit)
    .catch(exit)

  program.option("-v, --version", "output the version of the cli and desktop app", displayVersion)

  program
    .command("install")
    .description("Installs Cypress")
    .option("-d, --destination <path>", text("destination"))
    .option("--cypress-version <version>", text("version"))
    .action (opts) ->
      require("./commands/install").start(parseOpts(opts))

  program
    .command("update")
    .description("Updates Cypress to the latest version")
    .option("-d, --destination <path>", text("destination"))
    .action (opts) ->
      require("./commands/install").start(parseOpts(opts))

  program
    .command("run [project]")
    .usage("[project] [options]")
    .description("Runs Cypress Headlessly")
    .option("-r, --record [bool]",                       text("record"), coerceFalse)
    .option("-k, --key <record_key>",                    text("key"))
    .option("-s, --spec <spec>",                         text("spec"))
    .option("-r, --reporter <reporter>",                 text("reporter"))
    .option("-o, --reporter-options <reporter-options>", text("reporterOptions"))
    .option("-p, --port <port>",                         text("port"))
    .option("-e, --env <env>",                           text("env"))
    .option("-c, --config <config>",                     text("config"))
    .action (project, opts) ->
      require("./commands/run").start(project, parseOpts(opts))

  program
    .command("ci [key]")
    .usage("[key] [options]")
    .description("[DEPRECATED] Use 'cypress run --key <record_key>'")
    .option("-s, --spec <spec>",                         text("spec"))
    .option("-r, --reporter <reporter>",                 text("reporter"))
    .option("-o, --reporter-options <reporter-options>", text("reporterOptions"))
    .option("-p, --port <port>",                         text("port"))
    .option("-e, --env <env vars>",                      text("env"))
    .option("-c, --config <config>",                     text("config"))
    .action (key, opts) ->
      require("./commands/ci")(key, parseOpts(opts))

  program
    .command("open")
    .usage("[options]")
    .description("Opens Cypress normally, as a desktop application.")
    .option("-p, --port <port>",         text("port"))
    .option("-e, --env <env>",           text("env"))
    .option("-c, --config <config>",     text("config"))
    .action (opts) ->
      require("./commands/open")(parseOpts(opts))

  program
    .command("get:path")
    .description("Returns the default path of the Cypress executable")
    .action (key, opts) ->
      require("./commands/path")()

  program
    .command("get:key [project]")
    .description("Returns your Project's Secret Key for use in CI")
    .action (project) ->
      require("./commands/key")(project)

  program
    .command("new:key [project]")
    .description("Generates a new Project Secret Key for use in CI")
    .action (project) ->
      require("./commands/key")(project, {reset: true})

  program
    .command("remove:ids [project]")
    .description("Removes test IDs generated by Cypress in versions earlier than 0.14.0")
    .action (project) ->
      require("./commands/ids")(project)

  program
    .command("verify")
    .description("Verifies that Cypress is installed correctly and executable")
    .action ->
      require("./commands/verify")()

  program
    .command("version")
    .description("Outputs both the CLI and Desktop App versions")
    .action(displayVersion)

  program.parse(process.argv)

  ## if the process.argv.length
  ## is less than or equal to 2
  if process.argv.length <= 2
    ## then display the help
    program.help()

  return program
