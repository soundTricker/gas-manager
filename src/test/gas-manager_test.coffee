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

  describe '.Manager class', ()->

    Manager = null
    manager = null

    beforeEach ()->
      Manager = gas_manager.Manager

    it 'should be a function', ()->
      Manager.should.be.a('function')

    describe '.constructor',()->

      options = null

      beforeEach ()->
        options = JSON.parse fs.readFileSync "./tmp/test.json"
        manager = new Manager options
 
      it 'should be a constructor', ()->
        manager.should.be.a('object')

      it 'should be throw error, if does not set options' , ()->
        (()-> new Manager).should.throwError("should set options")

      it 'should have tokenProvider propety ',()->
        manager.should.have.property('tokenProvider')

      it 'should have option', ()->
        manager.should.have.property('options' , options)

    describe '.get', ()->

      beforeEach ()->
        options = JSON.parse fs.readFileSync "./tmp/test.json"
        manager = new Manager options

      it 'should get project', (done)->
        manager.get(FILE_ID
        ,(response , body)->
          body.should.be.a('object')
          body.should.have.property 'files'
          done()
        ,(err, result)-> 
          done()
        )
    describe '.upload',()->
      project = null
      before (done)->
        options = JSON.parse fs.readFileSync "./tmp/test.json"
        manager = new Manager options
        manager.get FILE_ID, (response, body)->
          project = body
          done()

      it 'should upload project', (done)->

        project.files[0].source += "//test";

        manager.upload(FILE_ID, project, (response , body)->
          manager.get FILE_ID, (response, body)->
            body.files[0].source.should.match(/\/\/test/)
            done()
        ,(err, response, body)->
          if err
            console.log body 
          done()
        )

