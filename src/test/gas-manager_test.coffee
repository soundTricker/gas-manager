'use strict'

gas_manager = require('../lib/gas-manager.js')
readline = require 'readline'
open = require 'open'
fs = require 'fs'
FILE_ID = "1jdu8QQcKZ5glzOaJnofi2At2Q-2PnLLKxptN0CTRVfgfz9ZIopD5sYXz"


###
======== A Handy Little Mocha Reference ========
https://github.com/visionmedia/should.js
https://github.com/visionmedia/mocha

Mocha hooks:
  before ()-> # before describe
  after ()-> # after describe
  beforeEach ()-> # before each it
  afterEach ()-> # after each it

Should assertions:
  should.exist('hello')
  should.fail('expected an error!')
  true.should.be.ok
  true.should.be.true
  false.should.be.false

  (()-> arguments)(1,2,3).should.be.arguments
  [1,2,3].should.eql([1,2,3])
  should.strictEqual(undefined, value)
  user.age.should.be.within(5, 50)
  username.should.match(/^\w+$/)

  user.should.be.a('object')
  [].should.be.an.instanceOf(Array)

  user.should.have.property('age', 15)

  user.age.should.be.above(5)
  user.age.should.be.below(100)
  user.pets.should.have.length(5)

  res.should.have.status(200) #res.statusCode should be 200
  res.should.be.json
  res.should.be.html
  res.should.have.header('Content-Length', '123')

  [].should.be.empty
  [1,2,3].should.include(3)
  'foo bar baz'.should.include('foo')
  { name: 'TJ', pet: tobi }.user.should.include({ pet: tobi, name: 'TJ' })
  { foo: 'bar', baz: 'raz' }.should.have.keys('foo', 'bar')

  (()-> throw new Error('failed to baz')).should.throwError(/^fail.+/)

  user.should.have.property('pets').with.lengthOf(4)
  user.should.be.a('object').and.have.property('name', 'tj')
###

describe 'gas-manager', ()->



  it "should have Manager property ",()->
    gas_manager.should.have.property('Manager')
    @

  describe '.Manager class', ()->

    Manager = null
    scriptManager = null

    before ()->
      Manager = gas_manager.Manager
      @

    it 'should be a function', ()->
      Manager.should.be.a('function')
      @

    describe '.constructor',()->

      options = null

      before ()->
        options = JSON.parse fs.readFileSync "./tmp/test.json"
        scriptManager = new Manager options
        @

      it 'should be a constructor', ()->
        scriptManager.should.be.a('object')
        @

      it 'should be throw error, if does not set options' , ()->
        (()-> new Manager).should.throwError("should set options")
        @

      it 'should have tokenProvider propety ',()->
        scriptManager.should.have.property('tokenProvider')
        @

      it 'should have option', ()->
        scriptManager.should.have.property('options' , options)
        @

    describe '.getProject', ()->

      before ()->
        options = JSON.parse fs.readFileSync "./tmp/test.json"
        scriptManager = new Manager options
        @

      it 'should get project', (done)->
        scriptManager.getProject(FILE_ID
        ,(response , project)->
          project.should.be.a('object')
          project.should.have.property 'origin'
          done()
        ,(err, result)-> 
          console.error err
          done("error")
        )
        @
    describe '.upload',()->
      project = null
      before (done)->
        options = JSON.parse fs.readFileSync "./tmp/test.json"
        scriptManager = new Manager options
        scriptManager.getProject FILE_ID, (response, p)->
          project = p
          done()
        @

      it 'should upload project', (done)->

        project.getFiles()[0].source += "//test";

        scriptManager.upload(FILE_ID, project
          ,(response, p)->
            scriptManager.getProject(FILE_ID, (response, p)->
              p.getFiles()[0].source.should.match(/\/\/test/)
              done()
            ,(err, response, project)->
              done("error")
            )
          ,(err, response, project)->
            if err
              console.log project
            done("error")
          )
        @
    describe '.createProject', ()->
      project = null
      before ()->
        options = JSON.parse fs.readFileSync "./tmp/test.json"
        scriptManager = new Manager options
        project = scriptManager.createProject 'test'
        @

      it "should be GASProject", ()->
        project.should.have.property "filename"
        project.filename.should.eql "test"
        @

    describe '.createNewProject', ()->
      fileId = null
      before ()->
        options = JSON.parse fs.readFileSync "./tmp/test.json"
        scriptManager = new Manager options
        @
      it "should create new gas project",(done)->
        scriptManager.createNewProject "test-test" , {
          files :[
            {
              name : "test"
              type : "server_js"
              source : "function a(){ Logger.log('a');}"
            }
          ]
        },
        (response, project)->
          project.filename.should.eql "test-test"
          console.log project.fileId
          fileId = project.fileId
          done()
        ,
        (error, response , body)->
          console.error error
          done("error")
        @
      after (done)->
        scriptManager.deleteProject(fileId
          ,()->
            done()
          ,(err , result)->
            done("error")
        )
        @



