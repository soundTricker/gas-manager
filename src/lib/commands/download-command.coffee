fs = require 'fs'
path = require 'path'
async = require 'async'
Manager = require('../gas-manager').Manager
util = require './util'


exports.download = (options)->
  program = @
  console.log "Start [download]...\n"

  config = util.loadConfig(program)
  manager = new Manager(config)
  fileId = program.fileId || config[program.env].fileId

  if !fileId
    throw new Error(
      "download command is given fileId in config file or -f <fileId>"
    )

  console.log "  Getting project..."
  manager.getProject(fileId, (err, project)->
    throw err if err
    console.log "  Got a [#{project.filename}] project"
    tasks = []
    console.log "  Creating files..."
    for file in project.getFiles()

      if file.type == "server_js"
        ext = ".js"
      else
        ext = ".html"

      if fileId != config[program.env]?.fileId
        filepath = path.resolve(options.path, file.name + ext)
      else
        confiPath = config[program.env]?.files?[file.name]?.path
        filepath = confiPath || path.resolve(options.path, file.name + ext)

      outPath = path.resolve(filepath)

      if !fs.existsSync path.dirname(outPath)
        fs.mkdirSync path.dirname(outPath)

      tasks.push do(outPath=outPath, file=file)->
        (cb)->
          fs.writeFile outPath, file.source, (err)->
            cb(err, [file.name , outPath])

    async.parallel tasks , (err, pathes)->
      throw err if err
      async.each pathes
      ,(path, cb)->
        console.log(
          "      [#{path[0]}] is created to \n       >>> [#{path[1]}]"
        )
        cb()
      ,(err)->
        throw err if err
        console.log "  Created files"
        console.log "Done."
  )