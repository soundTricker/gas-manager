fs = require 'fs'
path = require 'path'
async = require 'async'
Manager = require('../gas-manager').Manager
util = require './util'


exports.upload = (options)->
  program = @
  config = util.loadConfig(program)

  if !config[program.env]?.files
    throw new Error(
      "There is no [#{program.env}] enviroment setting at config file"
    )

  manager = new Manager(config)
  fileId = program.fileId || config[program.env].fileId

  if !fileId
    throw new Error(
      "upload command is given fileId in config file or -f {fileId}"
    )

  if options.src
    config[program.env] = 
      fileId : fileId
      files : options.src

  async.waterfall([
    (cb)->
      manager.getProject fileId, cb
    (project, response, cb)->
      readFiles = []
      for file in project.getFiles()
        
        if !config[program.env].files[file.name]
          project.deleteFile(file.name) if options.force
          continue

        readFiles.push(
          name : file.name
          setting : config[program.env].files[file.name]
        )

      async.parallel(
        readFiles.map((readFile)->
          return (callback)->
            fs.readFile(path.resolve(readFile.setting.path)
              ,encoding : options.encoding
              ,(err, source)->

                return callback(err) if err
                project.changeFile(readFile.name, {
                  type : readFile.setting.type
                  source : source
                })
                callback(null)
            )
        )
        ,(err)->
          throw err if err
          cb(null, project)
      )
    (project,cb)->
      project.deploy(cb)
  ],(err, project)->
    throw err if err
    console.log "Success uploading for #{project.filename}"
  )
