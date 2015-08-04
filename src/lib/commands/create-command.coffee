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


exports.create = (options)->
  program = @
  config = util.loadConfig(program)

  manager = new Manager(config)

  if options.src
    config[program.env] =
      files : options.src

  if !config[program.env]?.files
    throw new Error(
      "There is no [#{program.env}] enviroment setting at config file"
    )

  project = manager.createProject program.env
  async.waterfall([
    (cb)->
      async.parallel(
        do (tasks = []) ->
          for name,file of config[program.env].files
            tasks.push(
              do (name = name, file = file) ->
                (callback)->
                  fs.readFile(path.resolve(file.path)
                    ,encoding : options.encoding
                    ,(err, source)->
                      return callback(err) if err
                      project.addFile name, file.type, source
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
    console.log "Success creating for #{project.filename}; fileId: #{project.fileId}"
  )
