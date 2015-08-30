--------------------------------------------------------------------------
--  Application
--  Hosts a dependency scope and manages application resources
--
--  Documentation: https://www.github.com/DataDink/ModCraft
--------------------------------------------------------------------------

(function()
   local readonly, cycle, registry, join;
   local root = new .ModCraft:DependencyResolver();

   -- Application
   function class .ModCraft:Application()
      local scope = root.branch();
      scope.register.instance('dependencies', scope);
      scope.register.instance('application', self);

      local service = {};
      local backing = {};
      service.register = registry(scope, backing);
      service.resolve = scope.resolve;
      service.start = function()
         backing.module = function() error('Module added after start. Please use .dependency to register late dependencies.'); end
         backing.service = function() error('Service added after start. Please use .dependency to register late dependencies.'); end
         service.start = function() error('Application already started.'); end

         local modules = scope.resolve('modules');
         if (modules ~= nil) then
            if (#modules == 0) then modules = {modules} end;
            cycle(modules, 'init');
            cycle(modules, 'start');
         end
      end
      readonly(service, self);
   end

   function readonly(source, proxy, ex)
      return setmetatable(proxy or {}, {
         __metatable = false,
         __newindex = function() error('This object should remain readonly') end,
         __index = function(t, k) return source[k]; end,
         __pairs = function() return pairs(source); end,
         __call = ex
      });
   end

   function cycle(items, action)
      for _, item in pairs(items) do
         if (type(item[action]) == 'function') then
            item[action]();
         end
      end
   end

   function join(a, b)
      a = type(a) == 'string' and {a} or a;
      b = type(b) == 'string' and {b} or b;
      local concat = {};
      for _, v in ipairs(a) do table.insert(concat, v); end
      for _, v in ipairs(b) do table.insert(concat, v); end
      return concat;
   end

   -- A common registration interface for ModCraft
   function registry(scope, backing)
      backing = backing or {};
      backing.service = function(names, dependencies, constructor)
         scope.register.singleton(join(names, 'services'), dependencies, constructor);
      end
      backing.module = function(names, dependencies, constructor)
         scope.register.singleton(join(names, 'modules'), dependencies, constructor);
      end
      backing.dependency = readonly({
         instance = scope.register.instance,
         singleton = scope.register.singleton,
         contextual = scope.register.contextual,
         transient = scope.register.transient
      }, {}, scope.register.contextual);
      return readonly(backing);
   end

   -- Global registry
   ModCraft = readonly({
      register = registry(root),
      resolve = root.resolve,
      start = function()
         local application = new .ModCraft:Application();
         application.start();
         return application;
      end
   });
end)();
