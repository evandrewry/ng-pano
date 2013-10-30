module.exports = (grunt) ->
  grunt.initConfig
    compass:
      dist:
        options:
          require: ['animation']
          sassDir: 'sass'
          cssDir: 'css'

  grunt.loadNpmTasks 'grunt-contrib-compass'
  grunt.registerTask 'default', ['compass']
