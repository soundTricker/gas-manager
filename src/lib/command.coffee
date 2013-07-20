exports.run = ()->
  fs = require 'fs'
  path = require 'path'
  async = require 'async'
  Manager = require('./gas-manager').Manager
  program = require 'commander'

  loadConfig = (program)->
    if !fs.existsSync program.config
      throw new Error "#{program.config} not exist, it's given."

    config = require path.resolve program.config

    if !config.client_id
      throw new Error "config file should set client_id"
    if !config.client_secret
      throw new Error "config file should set client_secret"
    if !config.refresh_token
      throw new Error "config file should set refresh_token"

    return config

  download = (options)->
    console.log "Start [download]...\n"

    config = loadConfig(program)
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

        tasks.push do(outPath=outPath, name=file.name)->
          (cb)->
            fs.writeFile outPath, file.source, (err)->
              cb(err, [name , outPath])

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

  upload = (options)->
    config = loadConfig(program)

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
        console.log project.origin
        project.deploy(cb)
    ],(err, project)->
      throw err if err
      console.log "Success uploading for #{project.filename}"
    )

  program
    .version('0.2.0')
    .option('-f, --fileId <fileId>', "target gas project fileId")
    .option('-c, --config <path>', "config file path", "./gas-config.json")
    .option('-e, --env <env>', 'the enviroment of target sources', "src")

  program
    .command("download")
    .description("download google apps script file")
    .option('-p, --path <path>' , "download base path")
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

  program.parse(process.argv)