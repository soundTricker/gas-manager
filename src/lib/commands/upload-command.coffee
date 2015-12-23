###

gas-manager
https://github.com/soundTricker/gas-manager

Copyright (c) 2013 Keisuke Oohashi
Licensed under the MIT license.

###

'use strict'


fs = require 'fs'
path = require 'path'
async = require 'async'
Manager = require('../gas-manager').Manager
util = require './util'


exports.upload = (options)->
  program = @
  config = util.loadConfig(program)

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

  if !config[program.env]?.files
    throw new Error(
      "There is no [#{program.env}] enviroment setting at config file"
    )

  async.waterfall([
    (cb)->
      manager.getProject fileId, cb
    (project, response, cb)->
      readFiles = {}
      for file in project.getFiles()
        
        if !config[program.env].files[file.name]
          project.deleteFile(file.name) if options.force
          continue

        readFiles[file.name] =
          name : file.name
          setting : config[program.env].files[file.name]
          exist : yes

      if options.force
        for name,file of config[program.env].files
          if !readFiles[name]
            readFiles[name] =
              name : name
              setting : file
              exist : no

      async.parallel(
        do (tasks = []) ->
          for name,readFile of readFiles
            tasks.push(
              do (file = readFile) ->
                (callback)->
                  fs.readFile(path.resolve(file.setting.path)
                    ,encoding : options.encoding
                    ,(err, source)->
  
                      return callback(err) if err
                      if file.exist
                        project.changeFile(name, {
                          type : file.setting.type
                          source : source
                        })
                      else
                        project.addFile(name, {
                          type : file.setting.type
                          source : source
                        })
                      callback(null)
                  )
            )
          tasks
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
