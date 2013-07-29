module.exports = (grunt)->
  'use strict'

  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    notify_hooks:
      options:
        enabled : true
        max_jshint_notifications : 5
        title : 'Grunt Notify'
    notify:
      watch:
        options:
          title:"Watch complete"
          message : "Complete tasks"

    jshint:
      options:
        jshintrc: '.jshintrc'
      lib:
        src: ['src/lib/**/*.js']
      test:
        src: ['src/test/**/*.js']
    copy:
      main:
        files: [
            expand: true
            cwd: 'src/'
            src: ['**/*.js']
            dest: 'out/'
        ]
    coffeelint:
      gruntfile:
        src: 'Gruntfile.coffee'
      lib:
        src: ['src/lib/{,*/}*.coffee']
      test:
        src: ['src/test/{,*/}*.coffee']
      options:
        no_trailing_whitespace:
          level: 'error'
        max_line_length:
          level: 'warn'
    coffee:
      #compile:
      #  files:
      #    'out/lib/vender.js': ['src/vendor/*.coffee']
      lib:
        expand: true
        cwd: 'src/lib/'
        src: ['**/*.coffee']
        dest: 'out/lib/'
        ext: '.js'
      test:
        expand: true
        cwd: 'src/test/'
        src: ['**/*.coffee']
        dest: 'out/test/'
        ext: '.js'
    simplemocha:
      all:
        src: [
          'node_modules/assert/assert.js'
          'node_modules/should/lib/should.js'
          'out/test/**/*.js'
        ]
        options:
          globals: ['should']
          timeout: 30000
          ignoreLeaks: false
          #grep: '**/*.js'
          ui: 'bdd'
          reporter: 'spec'
    watch:
      gruntfile:
        files: '<%= coffeelint.gruntfile.src %>'
        tasks: ['coffeelint:gruntfile','notify:watch']
      jsLib:
        files: '<%= jshint.lib.src %>'
        tasks: ['jshint:lib','notify:watch']
      jsTest:
        files: '<%= jshint.test.src %>'
        tasks: ['jshint:test', 'simplemocha','notify:watch']
      coffee:
        files: '<%= coffeelint.lib.src %>'
        tasks: ['coffeelint:lib','coffee:lib','notify:watch']
      cofffeLib:
        files: '<%= coffeelint.lib.src %>'
        tasks: ['coffeelint:lib','coffee:lib', 'simplemocha','notify:watch']
      cofffeTest:
        files: '<%= coffeelint.test.src %>'
        tasks: ['coffeelint:test','coffee:test', 'simplemocha','notify:watch']
    clean: ['out/']

  # plugins.
  grunt.loadNpmTasks 'grunt-simple-mocha'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-jshint'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-notify'

  # tasks.
  grunt.registerTask 'compile', [
    'coffeelint'
    'jshint'
    'copy'
    'coffee'
  ]

  grunt.registerTask 'default', [
    'compile'
    'simplemocha'
  ]

  grunt.task.run 'notify_hooks'