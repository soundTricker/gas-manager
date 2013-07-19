fs = require 'fs'
path = require 'path'
Manager = require('./gas-manager').Manager
program = require 'commander'


loadConfig = (program)->
  if !fs.existsSync program.config
    throw new Error "#{program.config} not exist, it's given."

  config = require path.resolve program.config

  throw new Error "config file should set client_id" if !config.client_id
  throw new Error "config file should set client_secret" if !config.client_secret
  throw new Error "config file should set refresh_token" if !config.refresh_token
  return config

download = (options)->
  config = loadConfig(program)
  manager = new Manager(config)
  fileId = program.fileId || config.fileId

  if !fileId
    throw new Error "download option is given fileId in config file or -id {id}"

  manager.getProject(fileId, (err, project)->
    throw new Error "fail get project" , err
    for file in project.getFiles()

      if file.type == "server_js" 
        ext = ".js"
      else
        ext = ".html"

      if fileId != config.fileId
        filepath = path.resolve(options.path, file.name + ext)
      else
        filepath = config.src[file.name]?.path || path.resolve(options.path, file.name + ext)

      outPath = path.resolve(filepath)

      if !fs.existsSync path.dirname(outPath)
        fs.mkdirSync path.dirname(outPath)

      do(outPath=outPath)->
        fs.writeFile outPath, file.source, (err)->
          return console.error err if err
  )

upload = (options)->
  config = loadConfig(program)
  manager = new Manager(config)
  fileId = program.fileId || config.fileId

  if !fileId
    throw new Error "upload command is given fileId in config file or -id {id}"



program
  .version('0.2.0')
  .option('-f, --fileId [fileId]', "target gas project fileId")
  .option('-c, --config [path]', "config file path", "./gas-config.json")

program
  .command("download")
  .description("download google apps script file")
  .option('-p, --path <path>' , "download base path")
  .action(download)

program
  .command("upload")
  .description("upload google apps script file")
  .option('-p, --path [path]' ,"upload file dir. if set -s option, it will be overrided.")
  .option('-s, --sources [pathes ...]', "upload sources, if set it, -p option is overrided.")
  .action(upload)

program.parse(process.argv)