------------------------------------------------------------
--  ModCraft.lua
--  By DataDink
--
--  Source & Docs: https://www.github.com/DataDink/ModCraft
--  License: MIT
------------------------------------------------------------

(function()
   function createNS() -- This generates an isolated set of registration/construction namespace roots
      local classes = {};

      local function resolvename(base, key) return (#base == 0) and key or base .. '.' .. key; end

      -- Namespaces are virtual tables that can be traversed and assigned to dynamically
      local function namespace(base, intercept)
         base = tostring(base);
         return setmetatable({}, {
            path = base,
            __index = function(t, k)
               local name = resolvename(base, k);
               local class = classes[name];
               if (intercept and class) then return intercept(t, name, class) end
               return classes[name] or namespace(name);
            end,
            __newindex = function(t, k, v)
               if (intercept) then error('Invalid Operation'); end
               if (type(v) == 'function') then v = {constructor = v}; end
               if (type(v) ~= 'table') then error('Invalid Class Descriptor'); end
               local name = resolvename(base, k);
               classes[name] = v;
            end,
            __eq = function(a, b)
               if (type(a) == 'table') then a = getmetatable(a); end
               if (type(b) == 'table') then b = getmetatable(b); end
               if (type(a) == 'table') then a = a.path; end
               if (type(b) == 'table') then b = b.path; end
               return a == b;
            end,
            __tostring = function()
               return base;
            end
         });
      end

      -- Inherits static members starting at the most base descriptor
      local function buildInstance(descriptor)
         if (type(descriptor) ~= 'table') then return {}; end
         local instance = buildInstance(descriptor.inherits);
         for k, v in pairs(descriptor) do
            instance[k] = descriptor[k];
         end
         return instance;
      end

      -- Runs all constructors starting at the most base descriptor
      local function constructAll(descriptor, instance, ...)
         if (type(descriptor) ~= 'table') then return; end
         constructAll(descriptor.inherits, instance, ...);
         if (not descriptor.constructor) then return; end
         descriptor.constructor(instance, select(2, ...));
      end

      -- A namespace root that can have classes added to it
      local registration = namespace('');

      -- A namespace root that will return an executable constructor instead of a class
      local construction = namespace('', function(namespace, name, descriptor)
         local instance = buildInstance(descriptor);
         instance.__name = name;
         instance.__type = descriptor;
         instance.__namespace = namespace;
         instance.inherits = nil;
         instance.constructor = nil;
         return function(...)
            constructAll(descriptor, instance, ...);
            return instance;
         end
      end);

      -- class & new
      return registration, construction;
   end

   class, new = createNS(); -- Adds the global class/new keys

   function class:NameSpace() return createNS(); end -- Exposes custom namespace scoping
end)();
