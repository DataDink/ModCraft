------------------------------------------------------------
--  ModCraft.lua
--  By DataDink
--
--  Source & Docs: https://www.github.com/DataDink/ModCraft
--  License: MIT
------------------------------------------------------------

(function()
   local classes = {};

   function resolvename(base, key) return (#base == 0) and key or base .. '.' .. key; end

   function namespace(base, intercept)
      return setmetatable({}, {
         path = base,
         __index = function(t, k)
            local name = resolvename(base, k);
            local class = classes[name];
            if (intercept and class) then return intercept(t, name, class) end
            return classes[name] or namespace(name);
         end,
         __newindex = function(t, k, v)
            local name = resolvename(base, k);
            classes[name] = v;
         end,
         __eq = function(a, b)
            if (type(a) ~= 'table' or type(b) ~= 'table') then return false; end
            a = getmetatable(a); b = getmetatable(b);
            if ((not a) or (not b)) then return false; end;
            return a.path == b.path;
         end
      });
   end

   class = namespace('');

   function buildInstance(descriptor, instance)
      if (not descriptor) then return instance; end
      instance = instance or {};
      for k, v in pairs(descriptor) do
         if (not instance[k]) then
            instance[k] = descriptor[k];
         end
      end
      return buildInstance(descriptor.inherits, instance);
   end

   new = namespace('', function(namespace, name, descriptor)
      if (type(descriptor) ~= 'table') then error('Invalid Class Descriptor'); end
      local instance = buildInstance(descriptor);
      instance.__name = name;
      instance.__type = descriptor;
      instance.__namespace = namespace;
      return function(...)
         if (type(descriptor.constructor) == 'function') then
            descriptor.constructor(instance, select(2, ...));
         end
         return instance;
      end
   end);
end)();
