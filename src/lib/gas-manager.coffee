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

SCOPE =
  ['https://www.googleapis.com/auth/drive'
  'https://www.googleapis.com/auth/drive.file'
  'https://www.googleapis.com/auth/drive.scripts'
  ].join(" ")

ACCESS_TYPE= "offline"

DEFAULT_CREDENTIALS_DIR = './.tmp'

###*
 * The Manager class.
 *###
class Manager
  @DOWNLOAD_URL = "https://script.google.com/feeds/download/export?format=json&id="

  constructor:(@options)->
    if !options then throw new Error("should set options")

    @tokenProvider = new GoogleTokenProvider({
      'refresh_token' : @options.refresh_token,
      'client_id' : @options.client_id,
      'client_secret' : @options.client_secret,
    })

  get:(fileId, callback, errCallback)=>

    errCallback = errCallback || (err, results) -> console.log("error")

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
      ,(response, body, cb)->
        cb(null, response, JSON.parse(body))
      ,callback
    ]
    ,errCallback)

  upload:(fileId, gasProjectJson, callback , errCallback  )=>

    errCallback = errCallback || (err, results) -> console.log("error",results,err,"error")

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
          url : "https://www.googleapis.com/upload/drive/v2/files/#{fileId}",
          qs :{
            'access_token' : accessToken
          }
        }, cb)
      callback
    ]
    ,errCallback)



    # @oauth2Client.request {
    #   "method":"PUT"
    #   "uri":"https://www.googleapis.com/upload/drive/v2/files/#{fileId}"
    #   "headers" : {"content-type" :"application/vnd.google-apps.script+json"}
    #   "body" : JSON.stringify gasProjectJson
    # }, callback

exports.Manager = Manager
