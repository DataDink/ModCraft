/*************************************************************************
*  DependencyResolver
*
*  Documentation: https://www.github.com/DataDink/ModCraft
*************************************************************************/

// Create a new container: local container = new.ModCraft:DependencyResolver();
// Create a child container: local child = container.branch();
// Register a service: container.register.singleton('name', {'dependency', class.MyClass});
// Resolve a service: local service = container.resolve('name');
// Override a dependency: local service = container.resolve('name', {dependency: {}});
// Also available: register.instance(names, object), register.contextual(names, constructor), register.transient(names, constructor);
// Also available: (name, class), (name, {dependencies}, class), ({names}, {dependencies}, class), (name, {dependencies, class}), etc
(function()
   class. ModCraft.DependencyResolver = {
      constructor = function(resolver)
         var registry = {};

         resolver.register = {
            
         };
      end
   }
end)

(function() {

   class.DependencyResolver = {
      {
      var resolver = this;
      var registry = [];

      Object.defineProperty(resolver, 'register', {configurable: false, enumerable: true, value: {}});
      Object.defineProperty(resolver.register, 'instance', {configurable: false, enumerable: true, value:
         function(names, object) {
            var reg = new registration(names, [], function(){});
            reg.singleton = true;
            reg.instance = object;
            registry.push(reg);
         }
      });
      Object.defineProperty(resolver.register, 'singleton', {configurable: false, enumerable: true, value:
         function(names, dependencies, constructor) {
            var reg = new registration(names, dependencies, constructor);
            reg.singleton = true;
            registry.push(reg);
         }
      });
      Object.defineProperty(resolver.register, 'contextual', {configurable: false, enumerable: true, value:
         function(names, dependencies, constructor) {
            var reg = new registration(names, dependencies, constructor);
            reg.contextual = true;
            registry.push(reg);
         }
      });
      Object.defineProperty(resolver.register, 'transient', {configurable: false, enumerable: true, value:
         function(names, dependencies, constructor) {
            var reg = new registration(names, dependencies, constructor);
            registry.push(reg);
         }
      });

      Object.defineProperty(resolver, 'branch', {configurable: false, enumerable: true, value:
         function() {
            var child = new DependencyResolver();
            for (var i = 0; i < registry.length; i++) {
               var reg = registry[i];
               if ('instance' in reg && reg.singleton) { child.register.instance(reg.names, reg.instance); }
               else if (reg.singleton) { child.register.singleton(reg.names, reg.dependencies, reg.constructor); }
               else if (reg.contextual) { child.register.contextual(reg.names, reg.dependencies, reg.constructor); }
               else { child.register.transient(reg.names, reg.dependencies, reg.constructor); }
            }
            return child;
         }
      });

      Object.defineProperty(resolver, 'resolve', {configurable: false, enumerable: true, value:
         function(item, overrides) {
            var context = registry.map(function(r) { return r.singleton ? r : copy(r); });
            if (typeof(item) === 'string') { return resolveName(item, context, overrides || {}); }
            var dependencies = (arguments[0] instanceof Array) ? arguments[0] : [];
            var constructor = array(arguments).filter(function(a) { return typeof(a) === 'function'; })[0];
            var overrides = arguments[arguments.length - 1];

            overrides = !(overrides instanceof Array) && typeof(overrides) === 'object' ? overrides : {};
            constructor = typeof(constructor) === 'function' ? constructor
               : dependencies.filter(function(d) { return typeof(d) === 'function'; })[0];
            if (!constructor) { throw "Can't Resolve"; }

            var dependencies = dependencies.filter(function(d) { return typeof(d) === 'string'; });
            return resolveConstructor(dependencies, constructor, context, overrides);
         }
      });

      Object.defineProperty(resolver.resolve, 'all', {configurable: false, enumerable: true, value:
         function(item) {
            var resolves = resolver.resolve(item);
            return (resolves instanceof Array) ? resolves : [resolves];
         }
      });

      function resolveName(name, context, overrides) {
         if (name in overrides) { return overrides[name]; }
         var matches = context.filter(function(r) { return r.names.indexOf(name) >= 0; });
         var resolves = [];
         for (var i = 0; i < matches.length; i++) {
            var reg = matches[i];
            if ('instance' in reg) { resolves.push(reg.instance); }
            else {
               var instance = resolveConstructor(reg.dependencies, reg.constructor, context, overrides);
               resolves.push(instance);
               if (reg.singleton || reg.contextual) { reg.instance = instance; }
            }
         }
         return resolves.length > 1 ? resolves : resolves[0];
      }

      function resolveConstructor(dependencies, constructor, context, overrides) {
         var resolves = dependencies.map(function(d) { return resolveName(d, context, overrides); });
         function Dependency() { constructor.apply(this, resolves); }
         Dependency.prototype = constructor.prototype;
         return new Dependency();
      }
   }

   // Stores information about a dependency
   function registration(names, dependencies, constructor) {
      this.names = array(names).filter(function(n) { return typeof(n) === 'string'; });
      if (!this.names.length) { throw 'Invalid Name(s)'; }

      this.constructor = typeof(constructor) === 'function' ? constructor
         : typeof(dependencies) === 'function' ? dependencies
         : (dependencies instanceof Array) ? dependencies.filter(function(d) { return typeof(d) === 'function'; })[0]
         : false;
      if (!this.constructor) { throw 'Invalid Constructor'; }

      this.dependencies = array(dependencies).filter(function(d) { return typeof(d) === 'string'; });

      this.singleton = false;
      this.contextual = false;
   }

   function copy(from) { // shallow copy an object
      var to = {};
      for (var name in from) { to[name] = from[name]; }
      return to;
   }

   function array(from) { // if not already an array convert into one
      if (from instanceof Array) { return from; }
      if (typeof(from) === 'string') { return [from]; }
      try { return Array.prototype.slice.call(from, 0); }
      catch (error) { return typeof(from) === 'undefined' ? [] : [from]; }
   }

   Object.defineProperty(ModCraft, 'DependencyResolver', {configurable: false, enumerable: true, value: DependencyResolver});
})();
