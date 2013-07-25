fs = require 'fs'
path = require 'path'
async = require 'async'
Manager = require('./gas-manager').Manager
program = require 'commander'
util = require './commands/util'
download = require('./commands/download-command').download
upload = require('./commands/upload-command').upload

exports.run = ()->
  console.log util
  console.log util.getUserHome()

  init = ()->
    async.waterfall([
      (cb)->
        program.confirm('Do you have consumer_id and consumer_secret for Google OAuth2?',(ok)->
          process.stdin.destroy()
          cb(null, ok)
        )
    ], (err, result)-> @
    )

  program
    .version('0.3.1')
    .option('-f, --fileId <fileId>', "target gas project fileId")
    .option('-c, --config <path>', "credential config file path", "./gas-config.json")
    .option('-s, --setting <path>', "")
    .option('-e, --env <env>', 'the enviroment of target sources', "src")

  program
    .command("download")
    .description("download google apps script file")
    .option('-p, --path <path>' , "download base path", process.cwd())
    .action(download)

  program
    .command("upload")
    .description("upload google apps script file")
    .option(
      '-e, --encoding <encoding>'
      ,"The encoding of reading file", "UTF-8"
    )
    .option(
      '-F, --force'
      ,"if does not exist source in config.json but exist on server,
       server's file will be deleted"
      )
    .action(upload)

  program
    .command("init")
    .description("generate config file.")
    .action(init)

  program.parse(process.argv)