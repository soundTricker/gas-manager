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

  getProject : (fileId, callback, errCallback)=>

    errCallback = errCallback || (err, results) -> console.log(results,err)

    if !fileId
      throw new Error 'fileId id is given'

    async.waterfall([
      (cb)=>
          @tokenProvider.getToken(cb)
      ,(accessToken, cb)->
        request.get({
          url : Manager.DOWNLOAD_URL + fileId,
          qs :{
            'access_token' : accessToken
          }
        }, cb)
      ,(response, body, cb)=>
        filename = decodeURI(
          response.headers["content-disposition"]
          .split("''")[1].replace(/\.json$/,"")
        )
        project = new GASProject(filename, fileId, @, JSON.parse(body))
        cb(null
          ,response
          ,project)
      ,callback
    ]
    ,errCallback)

  createProject:(projectName)->
    return new GASProject projectName , null, @, {files : []}

  deleteProject:(fileId, callback, errCallback)->
    errCallback = errCallback || (err, results) -> console.log(results,err)
    if !fileId
      throw new Error 'fileId id is given'
    accessToken_ = null
    async.waterfall([
      (cb)=>
        @tokenProvider.getToken(cb)
      (accessToken, cb)=>
        request({
          method: 'delete',
          url : "#{API_ROOT}/files/#{fileId}"
          qs : {
            'access_token' : accessToken
          }
        }, cb)
      callback
    ], errCallback)


  createNewProject : (filename, gasProjectJson, callback , errCallback)=>
    errCallback = errCallback || (err, results) -> console.log(results,err)
    accessToken_ = null
    async.waterfall([
      (cb)=>
        @tokenProvider.getToken(cb)
      (accessToken, cb)->
        accessToken_ = accessToken
        request({
          method : 'post',
          body : JSON.stringify(gasProjectJson),
          headers : {
            "content-type" :"application/vnd.google-apps.script+json"
          }
          url : "#{UPLOAD_API_ROOT}/files",
          qs :{
            'convert' : true
            'access_token' : accessToken
          }
        }, cb)
      (response, body ,cb)=>
        result = JSON.parse(body)
        fileId = result.id
        title = result.title
        if filename
          request({
            method: 'put'
            json : {title:filename}
            url : "#{API_ROOT}/files/#{fileId}"
            qs :
              'access_token' : accessToken_
          }, (res, b)->
            project = new GASProject(filename, fileId, @, gasProjectJson)
            cb(null, response, project)
          )
          return

        cb(null, response, new GASProject(title, fileId, @,gasProjectJson))
      callback
    ],errCallback)

  upload:(fileId, gasProjectJson, callback , errCallback)=>

    errCallback = errCallback || (err, results) -> console.log(results,err)

    if !fileId
      throw new Error 'fileId id is given'

    async.waterfall([
      (cb)=>
          @tokenProvider.getToken(cb)
      (accessToken, cb)=>
        request({
          method : 'put',
          body : JSON.stringify(gasProjectJson),
          headers : {
            "content-type" :"application/vnd.google-apps.script+json"
          }
          url : "#{UPLOAD_API_ROOT}/files/#{fileId}",
          qs :{
            'access_token' : accessToken
          }
        }, cb)
      (response, body ,cb)=>
        {id, title} = JSON.parse(body)
        cb(null, response, new GASProject(title, id, @, gasProjectJson))
      callback
    ]
    ,errCallback)

  class GASProject
    constructor:(@filename, @fileId, @manager, @origin={files:[]})->
      if !@origin.files then @origin.files = []

    getFiles:()->
      return (new GASFile(@manager, origin) for origin in @origin.files)
        
    getFileByName:(filename)=>
      filtered = @origin.files.filter((file)-> file.name == filename)
      if filtered.length == 1
        return new GASFile(@manager, filtered[0])
      else
        return null
    
    addFile:(name, type, source)=>
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
    
    deploy:(callback, errorCallback)=>
      if @fileId
        @manager.upload(@fileId, @origin, callback, errorCallback)
      else
        @manager.createNewProject(@filename, @origin, callback, errorCallback)
        
    create:(callback, errorCallback)=>
      newProject = JSON.parse(JSON.stringify(@origin))
      delete file.id for k, file in newProject.files when file.id
      @manager.createNewProject(@filename, @origin, callback, errorCallback)
          
  class GASFile
    constructor:(@manager, @origin)->
      for k,v of @origin
        o = @origin
        Object.defineProperty(@, k,
          get : do(key=k)-> ()-> o[key]
          set : do(key=k)-> (value)-> o[key] = value
        )

exports.Manager = Manager