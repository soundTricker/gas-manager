###

gas-manager
https://github.com/soundTricker/gas-manager

Copyright (c) 2013 Keisuke Oohashi
Licensed under the MIT license.

###

fs = require 'fs'
path = require 'path'
async = require 'async'
Manager = require('../gas-manager').Manager
util = require './util'
open = require 'open'
googleapis = require 'googleapis'
colors = require 'colors'
CALLBACK_URL = 'urn:ietf:wg:oauth:2.0:oob'

SCOPE = [
  "https://www.googleapis.com/auth/drive"
  "https://www.googleapis.com/auth/drive.file"
  "https://www.googleapis.com/auth/drive.scripts"
].join(" ")
program = null
exports.init = (option)->
  program = @
  config = {}

  start = (cb)->
    console.log """

    #{'''===================
    Start gas-manager init
    ==================='''.green}

    This utility is will walk you through creating a gas-manager's config file.
    Press ^C at any time to quit.

    """.green

    program.confirm("Do you have client_id & client_secret for Google OAuth2? #{'[yes/no]'.green} ",(result)->
      if result is yes
        cb(null)
      else
        createConsumerKeyFlow(cb)
    )

  inputConsumerSecret = (cb)->
    program.prompt("Please input client_secret: " , (result)->
      if !result
        inputConsumerSecret(cb)
        return

      config.client_secret = result
      cb(null)
    )

  inputConsumerId = (cb)->
    program.prompt("Please input client_id: " , (result)->
      if !result
        inputConsumerId(cb)
        return

      config.client_id = result
      cb(null)
    )

  askRefreshToken = (cb)->
    program.confirm "Do you create refresh_token now? if yes, open browser. #{'[yes/no]'.green}  ", (result)->
      if result is yes
        createRefreshToken(cb)
      else
        program.prompt "Please input refresh_token: ",(result)->
          return askRefreshToken(cb) if !result
          config.refresh_token = result
          cb(null)

  createRefreshToken = (cb)->
    #TODO
    console.log """

    #{'''===================
    About a flow of creating refresh_token.
    ==================='''.green}

    I'll open browser.
    Then please do flow below.

    #{'  1. Choose account of authorize.'.green}
    #{'  2. Apploval an OAuth'.green}
    #{'  3. Enter a code , that will be shown in blowser, to the console.'.green}

    Then will create refresh_token.
    Okay? Let's begin creating refresh_token.

    """
    oauth2Client = new googleapis.OAuth2Client(config.client_id, config.client_secret, CALLBACK_URL)
    url = oauth2Client.generateAuthUrl({
      access_type: 'offline'
      scope: SCOPE
    })
    program.prompt "Press Enter Key, Open Browser. ", ()->
      open url , (err)->
        cb(err) if err
        enterCode = ()->
          program.prompt "Enter code: " , (result)->
            return enterCode() if !result
            oauth2Client.getToken result, (err, tokens)->
              cb(err) if err
              config.refresh_token = tokens.refresh_token
              cb(null)
        enterCode()


  saveCredentialToFile = (cb)->
    program.prompt "Save settings to file please input file path #{('[Default: ' + program.config + ']').green}: ", (result)->
      if !result
        result = program.config
      result = path.resolve(result)
      if !fs.existsSync path.dirname(result)
        fs.mkdirSync path.dirname(result)

      fs.writeFileSync result, JSON.stringify(config, "", 2)

      console.log "Created credential file to #{path.resolve(result).green}"
      cb(null)

  confirmCreatingProjectSetting = (cb)->
    program.confirm "Do you want to creating Project settings?  #{'[yes/no]'.green} ", (result)->
      if result is yes
        createProjectSettingFlow(config, cb)
      else
        cb(null)

  createCredentialflow = [
    start
    inputConsumerId
    inputConsumerSecret
    askRefreshToken
    saveCredentialToFile
    confirmCreatingProjectSetting
  ]

  if !option.onlyProject
    async.waterfall(createCredentialflow, (err, result)->
      throw err if err
      console.log "Finish."
      process.stdin.destroy()
      process.exit(0)
    )
  else
    createProjectSettingFlow(util.loadConfig(program), (err, result)->
      throw err if err
      console.log "Finish."
      process.stdin.destroy()
      process.exit(0)
    )

createProjectSettingFlow = (config, callback)->
  start = (cb)->
    program.prompt("Enter your need managing fileId of Google Apps Script Project: " , (result)->
      return start(cb) if !result
      cb(null, result)
    )

  getProject = (fileId, cb)->
    manager = new Manager config

    manager.getProject(fileId, cb)

  confirmProject = (project, response, cb)->
    filenames = project.getFiles().map((file)-> "#{file.name}  [type:#{file.type}]").join('\n  ')
    console.log """
      Is it your needing project?

      #{'Filename:'.green}
        #{project.filename}
      #{'Files:'.green}
        #{filenames}

    """

    program.confirm("Okay? #{'[yes/no]'.green} " , (result)->
      if result is yes
        cb(null, project)
      else
        cb("restart")
        createProjectSettingFlow(config, callback)
    )

  setEnvironment = (project, cb)->
    program.prompt("Enter your environment name #{('[Default: ' + program.env + ']').green} ", (result)->
      if !result
        result = program.env

      cb(null, project, result)
    )

  askWhereToCreatingFiles = (project, env, cb)->
    savedfiles = {}
    askWhereToCreatingFile = (file, files, basePath, cb2)->
      if file.type == "server_js"
        extension = ".js"
      else if file.type == "json"
        extension = ".json"
      else
        extension = ".html"
      filename = file.name + extension
      program.prompt("  > #{filename} #{('[Default: ' + path.resolve(basePath, filename) + ']').green}: ", (result)->
        if !result
          result =  path.resolve(basePath , filename)
        else
          reuslt = path.resolve(result)

        savedfiles[file.name] = {
          path : result
          type : file.type
        }
        cb2(null,files.pop(), files, basePath)
      )
    flow = []
    flow.push (cb)->
      program.prompt("Where is a base path of the project sources ? #{('[Default: ' + process.cwd() + ']').green}: ", (result)->
        if !result
          result = process.cwd()

        files = project.getFiles()
        console.log("Where do you want to create file to...")
        cb(null,files.pop(), files, result)
      )


    for i in project.getFiles()
      flow.push askWhereToCreatingFile

    async.waterfall flow , (err)->
      throw err if err
      cb(null, project, env, savedfiles)

  saveProjectSettingToFile = (project, env, files, cb)->
    program.prompt "Save settings to file, Please input file path #{('[Default: ' + program.setting + ']').green}: ", (result)->
      if !result
        result = program.setting
      result = path.resolve(result)
      if !fs.existsSync path.dirname(result)
        fs.mkdirSync path.dirname(result)

      setting = {}
      setting[env] =
        fileId : project.fileId
        files : files

      fs.writeFileSync result, JSON.stringify(setting, "", 2)

      console.log "Created project setting file to #{path.resolve(result).green}"
      cb(null)

  async.waterfall(
    [
      start
      getProject
      confirmProject
      setEnvironment
      askWhereToCreatingFiles
      saveProjectSettingToFile
    ], (err)->
      if err is "restart" then return
      if err then throw err
      if callback then callback(null)
  )

createConsumerKeyFlow = (callback)->

  start = (cb)->
    program.confirm("Do you create client_id and client_secret, if yes, open browser.  #{'[yes/no]'.green} ",(result)->
      if result is yes
        cb(null)
      else
        callback(null)
    )

  openBrowser = (cb)->

    console.log """

    #{'''===================
    About a flow of creating client_id and client_secret.
    ==================='''.green}

    I'll open browser to https://code.google.com/apis/console.
    Then please do flow below.

      #{'1. Creating new project in opened browser.'.green}
        1-1. Choose [Create...] at the upper left menu.
        1-2. Enter the name for your project in an opened dialog.

      #{'2. Add [Drive API] service.'.green}
        2-1. Click [Services] in the left sidebar.
        2-2. Set status to [ON] in Drive API.

      #{'3. Create client_id and client_secret.'.green}
        3-1. Click [API Access] in the left sidebar.
        3-2. Click [Create an OAuth2.0 client ID...]
        3-3. Enter the your [Product name] in an opened dialog , then Click [Next].
        3-4. Choose [Installed application] of 'Application Type'.
        3-5. Choose [Other] of 'Installed application type'.
        3-6. Click [Create client ID].

    Then Client ID(client_id) and Client Secret(client_secret) will be created.
    Okay? Let's begin creating client_id and client_secret.

    """

    program.prompt "Press Enter Key, Open Browser.", ()->
      open "https://code.google.com/apis/console" , (err)->
        cb(err) if err
        cb(null)

  async.waterfall([
    start
    openBrowser
  ]
  ,(err)->
    throw err if err
    callback(null)
  )
