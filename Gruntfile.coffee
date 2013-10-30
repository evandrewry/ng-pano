module.exports = (grunt) ->
  grunt.initConfig
    'sass-convert':
      options:
        from: 'sass'
        to: 'scss'
      dist:
        src: 'sass/**/*.sass'
        dest: 'css'

    sass:
      dist:
        files:
            'css/app.css': 'css/sass/app.scss'

  grunt.loadNpmTasks 'grunt-sass-convert'
  grunt.loadNpmTasks 'grunt-sass'
  grunt.registerTask 'default', ['sass-convert', 'sass']
