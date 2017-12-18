###

gas-manager
https://github.com/soundTricker/gas-manager

Copyright (c) 2013 Keisuke Oohashi
Licensed under the MIT license.

###

'use strict'

GoogleTokenProvider = require("refresh-token").GoogleTokenProvider
async = require 'async'
request = require 'request'

API_ROOT = "https://www.googleapis.com/drive/v2"
UPLOAD_API_ROOT = "https://www.googleapis.com/upload/drive/v2"
###*
 * The Manager class.
 *###
class Manager
  @DOWNLOAD_URL =
    "https://script.google.com/feeds/download/export?format=json&id="

  constructor:(@options)->
    if !options then throw new Error("should set options")

    @tokenProvider = new GoogleTokenProvider({
      'refresh_token' : @options.refresh_token,
      'client_id' : @options.client_id,
      'client_secret' : @options.client_secret,
    })

  getProject : (fileId, callback)=>

    callback = callback || (err, results)->
      if err then console.log(err,results)

    if !fileId
      throw new Error 'fileId id is given'

    async.waterfall([
      (cb)=>
          @tokenProvider.getToken(cb)
      ,(accessToken, cb)->
        request.get({
          url : Manager.DOWNLOAD_URL + fileId,
          qs :{
            'access_token' : accessToken,
            'supportsTeamDrives': true
          }
        }, cb)
      ,(response, body, cb)=>

        if response.statusCode != 200
          cb(body, null,response)
          return

        bodyJson = JSON.parse(body)
        if bodyJson.error
          cb(bodyJson, null,response)
          return

        filename = decodeURI(
          response.headers["content-disposition"]
          .split("''")[1].replace(/\.json$/,"")
        )
        project = new GASProject(filename, fileId, null, @, JSON.parse(body))
        cb(null
          ,project
          ,response)
    ]
    ,callback)

  createProject:(projectName, folderId)->
    return new GASProject projectName , null, folderId, @, {files : []}

  deleteProject:(fileId, callback)->
    callback = callback || (err, results)->
      if err then console.log(err,results)

    if !fileId
      throw new Error 'fileId id is given'
    accessToken_ = null
    async.waterfall([
      (cb)=>
        @tokenProvider.getToken(cb)
      (accessToken, cb)->
        request({
          method: 'delete',
          url : "#{API_ROOT}/files/#{fileId}"
          qs : {
            'access_token' : accessToken,
            'supportsTeamDrives': true
          }
        }, cb)
      (response, body, cb)->
        if response.statusCode != 200
          cb(body, null,response)
          return

        bodyJson = JSON.parse(body)
        if bodyJson.error
          cb(bodyJson, bodyJson,response)
          return

        cb(null, bodyJson, response)
    ], callback)


  createNewProject : (filename, folderId, gasProjectJson, callback)=>
    callback = callback || (err, results)->
      if err then console.log(err,results)

    accessToken_ = null
    async.waterfall([
      (cb)=>
        @tokenProvider.getToken(cb)
      (accessToken, cb)->
        accessToken_ = accessToken
        request({
          method : 'post',
          body : JSON.stringify(
              files: [
                  name : "dummy"
                  type : "server_js"
                  source : 'Logger.log("dummy")'
              ]
          ),
          headers : {
            "content-type" :"application/vnd.google-apps.script+json"
          }
          url : "#{UPLOAD_API_ROOT}/files",
          qs :{
            'convert' : true
            'access_token' : accessToken,
            'supportsTeamDrives': true
          }
        }, cb)
      (response, body, cb)=>

        if response.statusCode != 200
          cb("Bad status code #{response.statusCode}", body, response)
          return
        result = JSON.parse(body)

        if result.error
          cb(result, null,response)
          return
        if folderId
          @move(result.id, result.parents[0].id, folderId, cb)
          return
        cb(null, result.id)

      (fileId, cb)=>
        @upload(fileId, gasProjectJson, cb)

      (project, response ,cb)=>

        if response.statusCode != 200
          cb("Bad status code #{response.statusCode}",project, response)
          return

        fileId = project.fileId
        title = project.filename
        if filename
          request({
            method: 'put'
            json : {title:filename}
            url : "#{API_ROOT}/files/#{fileId}"
            qs :
              'access_token' : accessToken_,
              'supportsTeamDrives': true
          }, (err, res, b)->
            return cb(err, null, res) if err
            return cb("Bad status code #{res.statusCode}", null, res) if res.statusCode != 200
            result = b
            return cb(result, null, res) if result.error
            cb(null, new GASProject(filename, fileId, null, @, gasProjectJson), res)
          )
          return

        cb(null, new GASProject(title, fileId, null, @,gasProjectJson), response)
    ],callback)

  move:(fileId, fromFolderId, toFolderId, callback)->

    callback = callback || (err, results)->
      if err then console.log(err,results)

    if !fileId
      throw new Error 'fileId id is given'

    async.waterfall([
      (cb)=>
        @tokenProvider.getToken(cb)
      (accessToken, cb)->
        request({
          method : 'post',
          json : {id: toFolderId}
          url : "#{API_ROOT}/files/#{fileId}/parents",
          qs :{
            'access_token' : accessToken,
            'supportsTeamDrives': true
          }
        }, (err, response, body)->
          cb(null, accessToken, response, body)
        )
      (accessToken, response, body ,cb)->
        if response.statusCode != 200
          cb(body, null, response)
          return
        request({
          method : 'delete',
          url : "#{API_ROOT}/files/#{fileId}/parents/#{fromFolderId}",
          qs :{
            'access_token' : accessToken,
            'supportsTeamDrives': true
          }
        }, (response, body)->
          cb(null, fileId)
        )
    ], callback)

  upload:(fileId, gasProjectJson, callback)=>

    callback = callback || (err, results)->
      if err then console.log(err,results)

    if !fileId
      throw new Error 'fileId id is given'

    async.waterfall([
      (cb)=>
          @tokenProvider.getToken(cb)
      (accessToken, cb)->
        request({
          method : 'put',
          body : JSON.stringify(gasProjectJson),
          headers : {
            "content-type" :"application/vnd.google-apps.script+json"
          }
          url : "#{UPLOAD_API_ROOT}/files/#{fileId}",
          qs :{
            'access_token' : accessToken,
            'supportsTeamDrives': true
          }
        }, cb)
      (response, body ,cb)=>
        if response.statusCode != 200
          cb(body, null, response)
          return
        result = JSON.parse(body)

        if result.error
          cb(result, null, response)
          return

        {id, title} = JSON.parse(body)
        cb(null, new GASProject(title, id, null, @, gasProjectJson), response)
    ]
    ,callback)

  class GASProject
    constructor:(@filename, @fileId, @folderId, @manager, @origin={files:[]})->
      if !@origin.files then @origin.files = []

    getFiles:()->
      return (new GASFile(@manager, origin) for origin in @origin.files)
        
    getFileByName:(filename)=>
      filtered = @origin.files.filter((file)-> file.name == filename)
      if filtered.length == 1
        return new GASFile(@manager, filtered[0])
      else
        return null

    changeFile:(name , updated={}, addIfNone=true)=>

      throw new Error("name is given") if !name

      file = @getFileByName(name)
      if addIfNone && !file
        file = new GASFile(
          @manager
          ,{
            name : name
            type : "server_js"
            source : ""
          })

      throw new Error("does not exist file #{name}") if !file

      if typeof updated == 'function'
        updated(file)
        return @

      file.name = updated.name || file.name
      file.type = updated.type || file.type
      file.source = updated.source || file.source

      return @

    addFile:(name, type, source)=>

      throw new Error("exist same name file") if @getFileByName(name)?

      @origin.files.push(
        name : name
        type : type
        source : source
      )
      return @
        
    renameFile:(from , to)=>
      file = @getFileByName(from)
      file? && file.name = to
      return @
      
    deleteFile:(filename)=>
      @origin.files = @origin.files.filter((file)-> file.name != filename)
      return @
    
    deploy:(callback)=>
      if @fileId
        @manager.upload(@fileId, @origin, callback)
      else
        @manager.createNewProject(@filename, @folderId, @origin, callback)
        
    create:(callback)=>
      newProject = JSON.parse(JSON.stringify(@origin))
      delete file.id for k, file in newProject.files when file.id
      @manager.createNewProject(@filename, @folderId, @origin, callback)
          
  class GASFile
    constructor:(@manager, @origin)->
      for k,v of @origin
        o = @origin
        Object.defineProperty(@, k,
          get : do(key=k)-> ()-> o[key]
          set : do(key=k)-> (value)-> if o.id && key is "type" then console.warn "can't change type of existing file" else o[key] = value
        )

exports.Manager = Manager