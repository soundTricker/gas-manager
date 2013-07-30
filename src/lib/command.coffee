fs = require 'fs'
path = require 'path'
async = require 'async'
Manager = require('./gas-manager').Manager
program = require 'commander'
util = require './commands/util'


exports.run = ()->

  program
    .version('0.3.1')
    .option('-f, --fileId <fileId>', "target gas project fileId")
    .option('-c, --config <path>', "credential config file path", "#{path.resolve(util.getUserHome() , 'gas-config.json')}")
    .option('-s, --setting <path>', "project setting file path", "./gas-project.json")
    .option('-e, --env <env>', 'the environment of target sources', "src")

  program
    .command("download")
    .description("download google apps script file")
    .option('-p, --path <path>' , "download base path", process.cwd())
    .option(
      '-F, --force'
      ,"If a project source does not exist in project setting file, that is not downloaded."
    )
    .option(
      '-S, --src "<from:to...>"'
      ,"""\n\tThe source mapping between project file and local file.
      \tPlease set like below.
      \t  --src "code:./src/code.js index:./src/index.html"
      \tThis option is preferred all other options and setting file. 

      """
      ,(value)->
        return value.split(" ").reduce((map, source)->
          m = source.split(":")
          map[m[0]] = m[1]
          return map;
        ,{})
    )
    .action(require('./commands/download-command').download)

  program
    .command("upload")
    .description("upload google apps script file")
    .option(
      '-e, --encoding <encoding>'
      ,"The encoding of reading file", "UTF-8"
    )
    .option(
      '-F, --force'
      ,"If does not exist source in config.json but exist on server,
       server's file will be deleted"
      )
    .action(require('./commands/upload-command').upload)

  program
    .command("init")
    .description("generate config file.")
    .option(
      '-P --only-project'
      , "Creating only a project setting file"
    )
    .action(require('./commands/init-command').init)

  program.parse(process.argv)