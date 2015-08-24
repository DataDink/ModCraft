/*************************************************************************
*  Bootstrap
*  Configures and provides application startup
*
*  Documentation: https://www.github.com/DataDink/ModCraft
*************************************************************************/

// Starting the application: var application = ModCraft.start();
// Register a module: ModCraft.register.module('my-module', ['dependency', function(dependency) {}]);
// Also available: register.service, register.dependency, register.dependency.instance, register.dependency.singleton, register.dependency.contextual, register.dependency.transient
// Also available: (name, function), (name, [dependencies], function), ([names], [dependencies], function), (names, [dependencies, function]), etc

(function() {
   var root = new ModCraft.DependencyResolver();
   Object.defineProperty(ModCraft, 'register', {configurable: false, enumerable: true, value: {}});
   Object.defineProperty(ModCraft.register, 'service', {configurable: false, enumerable: true, value:
      function(names, dependencies, constructor) { root.register.singleton(and(names, 'services'), dependencies, constructor); }
   });
   Object.defineProperty(ModCraft.register, 'module', {configurable: false, enumerable: true, value:
      function(names, dependencies, constructor) { root.register.singleton(and(names, 'modules'), dependencies, constructor); }
   });
   Object.defineProperty(ModCraft.register, 'dependency', {configurable: false, enumerable: true, value:
      root.register.contextual
   });
   Object.defineProperty(ModCraft.register.dependency, 'instance', {configurable: false, enumerable: true, value:
      root.register.instance
   });
   Object.defineProperty(ModCraft.register.dependency, 'singleton', {configurable: false, enumerable: true, value:
      root.register.singleton
   });
   Object.defineProperty(ModCraft.register.dependency, 'contextual', {configurable: false, enumerable: true, value:
      root.register.contextual
   });
   Object.defineProperty(ModCraft.register.dependency, 'transient', {configurable: false, enumerable: true, value:
      root.register.transient
   });
   Object.defineProperty(ModCraft, 'resolve', {configurable: false, enumerable: true, value:
      root.resolve
   });
   Object.defineProperty(ModCraft, 'start', {configurable: false, enumerable: true, value:
      function() {
         console.log('Starting Application');
         var scope = root.branch();
         scope.register.instance('dependencies', scope);

         var application = scope.resolve(['dependencies', ModCraft]);
         scope.register.instance('application', application);

         console.log('Loading Modules');
         var modules = scope.resolve.all('modules');
         function cycle(action, title) {
            for (var i = 0; i < modules.length; i++) {
               var module = modules[i];
               if (!(action in module)) { continue; }
               var name = module.name || 'a module';
               console.log(title + ' ' + name);
               module[action]();
            }
         }
         cycle('init', 'Initializing');
         cycle('start', 'Starting');
         console.log('Application Ready');
         return application;
      }
   });

   function and(a, b) {
      a = (a instanceof Array) ? a : typeof(a) === 'string' ? [a] : [];
      b = (b instanceof Array) ? b : typeof(b) === 'string' ? [b] : [];
      return a.concat(b);
   }
})();
