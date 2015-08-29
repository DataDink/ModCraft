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
   local readonly, createRegistration, strings, constructor, createContext, resolveName, resolveConstructor; -- helper declarations

   class. ModCraft.DependencyResolver = {
      constructor = function(self)
         local resolveName, resolveConstructor;

         var resolver = {};
         var registry = {};

         resolver.register = readonly({
            instance = function(names, object)
               local reg = createRegistration(false, names);
               reg.singleton = true;
               reg.instance = object;
               table.insert(registry, reg);
            end,
            singleton = function(names, dependencies, class)
               local reg = createRegistration(true, names, dependencies, class);
               reg.singleton = true;
               table.insert(registry, reg);
            end,
            contextual = function(names, dependencies, class)
               local reg = createRegistration(true, names, dependencies, class);
               reg.contextual = true;
               table.insert(registry, reg);
            end,
            transient = function(names, dependencies, class)
               local reg = createRegistration(true, names, dependencies, class);
               table.insert(registry, reg);
            end,
         });

         resolver.branch = function()
            local child = new .ModCraft:DependencyResolver();
            for _, reg in ipairs(registry) do
               if (reg.instance ~= nil) then child.register.instance(reg.names, reg.instance); end
               elseif (reg.singleton) then child.register.singleton(reg.names, reg.dependencies, reg.class); end
               elseif (reg.contextual) then child.register.contextual(reg.names, reg.dependencies, reg.class); end
               else child.register.transient(reg.names, reg.dependencies, reg.class); end
            end
            return child;
         end

         resolver.resolve = function(...)
            local context = createContext(registry);
            local name, overrides = select(1, ...);
            if (type(name) == 'string') then return resolveName(name, context, overrides or {}); end

            local class, overrides = select(1, ...);
            local ctor = constructor(class);
            if (ctor) then return resolveConstructor({}, ctor, context, overrides or {}); end

            local dependencies, class, overrides = select(1, ...);
            local ctor = constructor(class);
            if (ctor) then return resolveConstructor(dependencies, ctor, context, overrides or {}); end

            local group, overrides = select(1, ...);
            local class = table.remove(group);
            local ctor = constructor(class);
            if (ctor) then return resolveConstructor(group, ctor, context, overrides or {});

            error("Can't resolve requested signature");
         end

         readonly(resolver, self);
      end
   }

   -- Fronts a table with a readonly proxy
   function readonly(table, proxy)
      proxy = proxy or {};
      setmetatable(proxy, {
         __index = function(t, k) return resolver[k]; end,
         __newindex = function() error('This object should remain read-only') end,
      });
      return proxy;
   end

   -- Maintains information about a dependency
   function createRegistration(require, names, dependencies, class)
      local reg = {names = {}, dependencies = {}, constructor = false, singleton = false, contextual = false};

      -- Names
      reg.names = strings(names);
      if (#reg.names == 0) then error('No name(s) specified'); end

      -- Constructor
      local ctor = constructor(dependencies);
      if (ctor) then dependencies = {}; end
      if (not ctor) then ctor = constructor(class); end
      if (not ctor and type(dependencies) == 'table') then ctor = constructor(table.remove(dependencies)); end
      if (not ctor and require) then error('Class not specified'); end

      -- Dependencies
      reg.dependencies = strings(dependencies);

      return reg;
   end

   -- Ensures a collection of strings or empty collection
   function strings(items)
      items = (type(items) == 'table') and items or {items};
      local filtered = {};
      for _, v in ipairs(items) do
         if (type(v) == 'string') then table.insert(filtered, v); end
      end
      return filtered;
   end

   -- Maintains referencial integrity between resolution contexts
   function createContext(registry)
      local context = {};
      for _, reg in ipairs(registry) do
         if (reg.singleton) then table.insert(context, reg);
         else table.insert(context, {
            names = reg.names,
            dependencies = reg.dependencies,
            constructor = reg.constructor,
            singleton = reg.singleton,
            contextual = reg.contextual
         });
      end
      return context;
   end

   -- Identifies and extracts a class construction method or false
   function constructor(class)
      if (type(class) ~= 'table') then return false; end
      if (type(class.__name) ~= 'string') then return false; end
      local name = class.__name;
      if (type(class.__namespace) ~= 'table') then return false; end
      local namespace = tostring(class.__namespace);
      if (string.sub(name, 1, #namespace) ~= namespace) then return false; end
      name = string.sub(name, #namespace);

   end
end)

(function() {

   class.DependencyResolver = {
      {

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
