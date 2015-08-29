/*************************************************************************
*  Application
*  Hosts a dependency scope and manages application resources
*
*  Documentation: https://www.github.com/DataDink/ModCraft
*************************************************************************/

// Starting an application: var application = ModCraft.start();
// You can also construct a new ModCraft.Application and call the .start() method;
// Register a global module: ModCraft.register.module('my-module', ['dependency', function(dependency) {}]);
// Register an application module: (new ModCraft.Application()).register.module('my-module', ['dependency', function(dependency) {}]);
// Also available: register.service, register.dependency, register.dependency.instance, register.dependency.singleton, register.dependency.contextual, register.dependency.transient
// Also available: (name, function), (name, [dependencies], function), ([names], [dependencies], function), (names, [dependencies, function]), etc

(function() {
   var root = new ModCraft.DependencyResolver();

   ModCraft.Application = function() {
      var scope = root.branch();
      scope.register.instance('dependencies', scope);
      scope.register.instance('application', this);

      var backing = {};
      Object.defineProperty(this, 'register', {configurable: false, enumerable: true, value:
         new registry(scope, backing)
      });
      Object.defineProperty(this, 'resolve', {configurable: false, enumerable: true, value: scope.resolve});
      function start() {
         backing.module = function() { throw 'Module added after start. Please use .dependency to register late dependencies.'; };
         backing.service = function() { throw 'Service added after start. Please use .dependency to register late dependencies.'; };
         start = function() { throw 'Application already started.'; }

         console.log('Starting Application');
         console.log('Loading Modules');
         var modules = scope.resolve.all('modules');
         cycle(modules, 'init', 'Initializing');
         cycle(modules, 'start', 'Starting');
         console.log('Application Ready');
      }
      Object.defineProperty(this, 'start', {configurable: false, enumerable: true, get: function() { return start; }});
      Object.freeze(this);
   };

   function cycle(items, action, title) {
      for (var i = 0; i < items.length; i++) {
         var item = items[i];
         if (typeof(item[action]) !== 'function') { continue; }
         var name = item.name || 'nameless';
         console.log(title + ' ' + name);
         item[action]();
      }
   }

   // A common registration interface for ModCraft
   function registry(scope, backing) {
      backing = backing || {};
      backing.service = function(names, dependencies, constructor) {
         scope.register.singleton(and(names, 'services'), dependencies, constructor);
      };
      Object.defineProperty(this, 'service', {configurable: false, enumerable: true, get: function() { return backing.service; }});
      backing.module = function(names, dependencies, constructor) {
         scope.register.singleton(and(names, 'modules'), dependencies, constructor);
      };
      Object.defineProperty(this, 'module', {configurable: false, enumerable: true, get: function() { return backing.module; }});

      backing.dependency = scope.register.contextual;
      Object.defineProperty(this, 'dependency', {configurable: false, enumerable: true, get: function() { return backing.dependency; }});
      backing.instance = scope.register.instance;
      Object.defineProperty(this.dependency, 'instance', {configurable: false, enumerable: true, get: function() { return backing.instance; }});
      backing.singleton = scope.register.singleton;
      Object.defineProperty(this.dependency, 'singleton', {configurable: false, enumerable: true, get: function() { return backing.singleton; }});
      backing.contextual = scope.register.contextual;
      Object.defineProperty(this.dependency, 'contextual', {configurable: false, enumerable: true, get: function() { return backing.contextual; }});
      backing.transient = scope.register.transient;
      Object.defineProperty(this.dependency, 'transient', {configurable: false, enumerable: true, get: function() { return backing.transient; }});
   }

   // Setting global pre-application registers
   Object.defineProperty(ModCraft, 'register', {configurable: false, enumerable: true, value:
      new registry(root)
   });
   Object.defineProperty(ModCraft, 'resolve', {configurable: false, enumerable: true, value:
      root.resolve
   });
   Object.defineProperty(ModCraft, 'start', {configurable: false, enumerable: true, value:
      function() {
         var application = new ModCraft.Application();
         application.start();
         return application;
      }
   });

   function and(a, b) {
      a = (a instanceof Array) ? a : typeof(a) === 'string' ? [a] : [];
      b = (b instanceof Array) ? b : typeof(b) === 'string' ? [b] : [];
      return a.concat(b);
   }
})();
