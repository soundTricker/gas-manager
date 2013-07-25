fs = require 'fs'
path = require 'path'
async = require 'async'
Manager = require('../gas-manager').Manager
util = require './util'

init = ()->
  async.waterfall([
    (cb)->
      program.confirm('Do you have consumer_id and consumer_secret for Google OAuth2?',(ok)->
        process.stdin.destroy()
        cb(null, ok)
      )
  ], (err, result)-> @
  )
