module.exports = function(grunt) {
   grunt.initConfig({
      concat: {
         options: { separator: ';\r\n\r\n' },
         modcraft: {
            src: [
               // core
               'Source/ModCraft.js',
               'Source/DependencyResolver.js',
               'Source/Application.js',
            ],
            dest: 'Builds/modcraft.js'
         }
      },
      uglify: {
         index: { src: 'Builds/modcraft.js', dest: 'Builds/modcraft.min.js' }
      }
   });

   grunt.loadNpmTasks('grunt-contrib-concat');
   grunt.loadNpmTasks('grunt-contrib-uglify');
   grunt.registerTask('build-all', ['concat', 'uglify']);
};
