module.exports = function(grunt) {
   var luamin = require('luamin/luamin.js');

   grunt.initConfig({
      concat: {
         options: { separator: '\r\n\r\n--\r\n\r\n' },
         modcraft: {
            src: [
               // core
               'Source/ModCraft.lua',
               'Source/DependencyResolver.lua',
               'Source/Application.lua',
            ],
            dest: 'Builds/modcraft.lua'
         }
      },
      minify: {
         modcraft: {
            src: 'Builds/modcraft.lua',
            dest: 'Builds/modcraft.min.lua'
         }
      }
   });

   grunt.registerMultiTask('minify', 'Minifies Lua', function() {
      this.files.forEach(function(f) {
         var raw = grunt.file.read(f.src);
         var min = luamin.minify(raw);
         grunt.file.write(f.dest, min);
      });
   });
   grunt.loadNpmTasks('grunt-contrib-concat');
   grunt.registerTask('build-all', ['concat', 'minify']);
};
