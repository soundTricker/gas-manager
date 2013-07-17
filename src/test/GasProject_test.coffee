'use strict'

Manager = require('../lib/gas-manager.js').Manager
readline = require 'readline'
open = require 'open'
fs = require 'fs'
fileId = "1jdu8QQcKZ5glzOaJnofi2At2Q-2PnLLKxptN0CTRVfgfz9ZIopD5sYXz"
options = JSON.parse fs.readFileSync "./tmp/test.json"
scriptManager = new Manager options
should = require "should"

describe "GASProject", ()->
  describe "#constructor",()->
    project = null
    before (done)->
      scriptManager.getProject(fileId, (err, p)->
        return done(err) if err
        project = p
        done()
      )
      @

    it "should set properties, fileId, filename, manager, origin", ()->
      project.fileId.should.eql fileId
      project.should.have.property('filename')
      project.should.have.property('manager')
      @

    describe "#getFiles", ()->

      it "should get files as a GASFile", ()->
        files = project.getFiles()
        files.should.be.an.instanceOf(Array)
        @
      @

    describe "#getFileByName", ()->
      it "should get a file by filename", ()->
        code = project.getFileByName("code")
        code.should.have.property 'origin'
        @

      it "should return null, if not found", ()->
        should.not.exist project.getFileByName("")
        @
      @

    describe "#addFile",()->
      beforeEach (done)->
        scriptManager.getProject(fileId, (err, p)->
          return done(err) if err
          project = p
          done()
        )
        @

      it "should add file to own", ()->
        filename = new Date().toString()
        project.addFile(filename, "server_js", "//code")
        file = project.getFileByName(filename)
        should.exist(file)
        file.name.should.eql filename
        file.type.should.eql "server_js"
        file.source.should.eql "//code"
        @
      it "should return own", ()->
        p = project.addFile("hoge", "html", "fuga")
        p.should.equal project
        @

      after (done)->
        scriptManager.getProject(fileId, (err, p)->
          return done(err) if err
          project = p
          done()
        )
        @
      @

    describe "#renameFile", ()->
      project = null
      beforeEach (done)->
        scriptManager.getProject(fileId,(err, p)->
          return done(err) if err
          project = p
          project.addFile("test-2" , "server_js", "test")
          done()
        )
        @

      it "should rename child file", ()->
        filename = new Date().toString()
        project.renameFile("test-2", filename)
        file = project.getFileByName(filename)
        should.exist file
        should.not.exist project.getFileByName("test-2")
        @
      it "should return own", ()->
        p = project.renameFile("test", "fuga")
        p.should.equal project
        @
      @
    describe "#deleteFile", ()->
      project = null
      beforeEach (done)->
        scriptManager.getProject(fileId,(err, p)->
          return done(err) if err
          project = p
          project.addFile("test" , "server_js", "test")
          done()
        )
        @

      it "should delete a file by name", ()->
        project.deleteFile("test")
        should.not.exist project.getFileByName("test")
        @

      it "should not throw error if file is not found", ()->
        (()->project.deleteFile("hoge")).should.not.throwError()
        @
      @
    describe "#changeFile", ()->
      project = null
      beforeEach (done)->
        scriptManager.getProject(fileId,(err, p)->
          return done(err) if err
          p.deleteFile("test").deploy((err, p, res)->
            return done(err) if err
            project = p.addFile("test" , "server_js", "//test")
            done()
          )
        )
        @

      it "should change file", ()->
        file = JSON.parse(JSON.stringify(project.getFileByName("test").origin))

        p = project.changeFile("test" , name : "huga" , source : "//test2" , type:"html")

        should.not.exist project.getFileByName("test")
        changedFile = project.getFileByName("huga")
        should.exist changedFile
        changedFile.name.should.eql "huga" 
        changedFile.type.should.eql "html" 
        changedFile.source.should.eql "//test2" 
        p.should.equal project
        @

      it "should change file only setting property", ()->
        file = JSON.parse(JSON.stringify(project.getFileByName("test").origin))

        project.changeFile("test" , source : "//test2")

        changedFile = project.getFileByName("test")
        should.exist changedFile
        changedFile.name.should.eql file.name 
        changedFile.type.should.eql file.type
        changedFile.source.should.eql "//test2" 
        @

      it "should allow functional parameter", ()->
        file = JSON.parse(JSON.stringify(project.getFileByName("test").origin))

        project.changeFile("test" , (testFile)-> testFile.source = testFile.source + "//test2")

        changedFile = project.getFileByName("test")
        should.exist changedFile
        changedFile.name.should.eql file.name 
        changedFile.type.should.eql file.type
        changedFile.source.should.eql file.source + "//test2" 
        @


    describe "#deploy",()->
      project = null
      before (done)->
        scriptManager.getProject(fileId,(err, p)->
          return done(err) if err
          p.deleteFile("test").deploy((err, p, res)->
            return done(err) if err
            project = p.addFile("test" , "server_js", "//test")
            done()
          )
        )
        @

      it "should deploy project", (done)->
        project
        .deploy((err, newProject, res)->
          return done(err) if err
          scriptManager.getProject(fileId,(err, reget)->
            return done(err) if err
            should.exist reget.getFileByName("test")
            newProject.fileId.should.eql reget.fileId
            project.deleteFile("test").deploy((err, p)->
              return done(err) if err
              done()
            )
          )
        )
        @

      it "should create new project, if does not have fileId", (done)->
        scriptManager.createProject("new project")
        .addFile("hoge", "server_js", "//test")
        .deploy((err, newProject, res)->
          return done(err) if err
          scriptManager.getProject(newProject.fileId,(err, reget)->
            return done(err) if err
            newProject.fileId.should.eql reget.fileId
            should.exist newProject.getFileByName("hoge")
            newProject.filename.should.eql "new project"
            scriptManager.deleteProject(newProject.fileId, ()-> done())
          )
        )
        @
      @
    @
  @