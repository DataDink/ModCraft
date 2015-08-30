--------------------------------------------------------------------------
--  DependencyResolver
--
--  Documentation: https://www.github.com/DataDink/ModCraft
--------------------------------------------------------------------------

-- Create a new container: local container = new.ModCraft:DependencyResolver();
-- Create a child container: local child = container.branch();
-- Register a service: container.register.singleton('name', {'dependency', class.MyClass});
-- Resolve a service: local service = container.resolve('name');
-- Override a dependency: local service = container.resolve('name', {dependency: {}});
-- Also available: register.instance(names, object), register.contextual(names, constructor), register.transient(names, constructor);
-- Also available: (name, class), (name, {dependencies}, class), ({names}, {dependencies}, class), (name, {dependencies, class}), etc
(function()
   local createRegistration, readonly, strings, constructor, createContext, resolveName, resolveConstructor; -- helper declarations

   class .ModCraft.DependencyResolver = {
      constructor = function(self)
         local resolver = {};
         local registry = {};

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
            end
         });

         resolver.branch = function()
            local child = new .ModCraft:DependencyResolver();
            for _, reg in ipairs(registry) do
               if (reg.instance ~= nil) then child.register.instance(reg.names, reg.instance);
               elseif (reg.singleton) then child.register.singleton(reg.names, reg.dependencies, reg.class);
               elseif (reg.contextual) then child.register.contextual(reg.names, reg.dependencies, reg.class);
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
            if (ctor) then return resolveConstructor(group, ctor, context, overrides or {}); end

            error("Can't resolve requested signature");
         end

         readonly(resolver, self);
      end
   };

   -- Fronts a table with a readonly proxy
   function readonly(backing, proxy)
      return setmetatable(proxy or {}, {
         __metatable = false,
         __newindex = function() error('This object should remain read-only') end,
         __index = function(t, k) return backing[k]; end,
         __pairs = function() return pairs(backing); end
      });
   end

   -- Maintains information about a dependency
   function createRegistration(require, names, dependencies, class)
      local reg = {names = {}, dependencies = {}, constructor = false, singleton = false, contextual = false};

      -- Names
      reg.names = strings(names);
      if (#reg.names == 0) then error('No name(s) specified'); end

      -- Constructor
      reg.constructor = constructor(dependencies);
      if (reg.constructor) then
         reg.class = dependencies;
         dependencies = {};
      end
      if (not reg.constructor) then
         reg.class = class;
         reg.constructor = constructor(class);
      end
      if (not reg.constructor and type(dependencies) == 'table') then
         reg.class = table.remove(dependencies);
         reg.constructor = constructor(reg.class);
      end
      if (not reg.constructor and require) then error('Class not specified'); end

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
      local ctor = class.__namespace(name);
      if (not ctor) then return false; end
      return function(...) return ctor(nil, ...); end
   end

   function resolveName(name, context, overrides)
      if (overrides[name] ~= nil) then return overrides[name]; end
      local matches = {};
      for _, r in pairs(context) do
         for _, n in pairs(r.names) do
            if (n == name) then
               table.insert(matches, r);
               break;
            end
         end
      end
      local resolves = {};
      for _, m in pairs(matches) do
         if (m.instance ~= nil) then table.insert(resolves, m.instance);
         else
            local instance = resolveConstructor(m.dependencies, m.constructor, context, overrides);
            table.insert(resolves, instance);
            if (m.singleton or m.contextual) then m.instance = instance; end
         end
      end
      return (#resolves > 1) and resolves or resolves[1];
   end

   function resolveConstructor(dependencies, ctor, context, overrides)
      local resolves = {};
      for _, n in pairs(dependencies) do
         table.insert(resolves, resolveName(n, context, overrides));
      end
      return ctor(args(resolves));
   end

   function args(dependencies)
      if (#dependencies > 0) then
         return table.remove(dependencies, 1), args(dependencies);
      end
   end
end)();
