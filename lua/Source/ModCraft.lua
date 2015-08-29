------------------------------------------------------------
--  ModCraft.lua
--  By DataDink
--
--  Source & Docs: https://www.github.com/DataDink/ModCraft
--  License: MIT
------------------------------------------------------------

(function()
   function createNS() -- This generates an isolated set of registration/construction namespace roots
      local constructor, buildInstance, constructAll;
      local descriptors = {};

      local function resolvename(base, key) return (#base == 0) and key or base .. '.' .. key; end

      -- Namespaces are virtual tables that can be traversed and assigned to dynamically
      local function namespace(base, resolve)
         base = tostring(base);
         return setmetatable({}, {
            -- maintain metatable integrity
            __metatable = false,

            -- return requested class or next virtual namespace
            __index = function(t, k)
               local name = resolvename(base, k);
               local descriptor = descriptors[name];
               if (resolve and descriptor) then return t(k); end
               return descriptors[name] or namespace(name, resolve);
            end,

            -- register a new class descriptor
            __newindex = function(ns, k, v)
               if (resolve) then error('Invalid Operation'); end
               if (type(v) == 'function') then v = {constructor = v}; end
               if (type(v) ~= 'table') then error('Invalid Class Descriptor'); end
               local name = resolvename(base, k);
               descriptors[name] = setmetatable({}, {
                  __metatable = false,
                  __newindex = function() error('class descriptors should not be edited'); end,
                  __index = function(c, k)
                     if (k == '__name') then return name; end
                     if (k == '__namespace') then return ns; end
                     return v[k];
                  end,
                  __pairs = function() return pairs(v); end
               });
            end,

            -- generate a constructor function
            __call = function(t, k)
               local name = resolvename(base, k);
               local descriptor = descriptors[name];
               if (not descriptor) then return false; end
               return constructor(t, name, descriptor);
            end,

            -- compares namespaces
            __eq = function(a, b)
               if (type(a) == 'table') then a = getmetatable(a); end
               if (type(b) == 'table') then b = getmetatable(b); end
               if (type(a) == 'table') then a = a.path; end
               if (type(b) == 'table') then b = b.path; end
               return a == b;
            end,

            -- resolve namespace path
            __tostring = function()
               return base;
            end
         });
      end

      -- Inherits static members starting at the most base descriptor
      function buildInstance(descriptor)
         if (type(descriptor) ~= 'table') then return {}; end
         local instance = buildInstance(descriptor.inherits);
         for k, v in pairs(descriptor) do
            if (k ~= 'inherits'
            and k ~= 'constructor') then
               instance[k] = descriptor[k];
            end
         end
         return instance;
      end

      -- Runs all constructors starting at the most base descriptor
      function constructAll(descriptor, instance, ...)
         if (type(descriptor) ~= 'table') then return; end
         constructAll(descriptor.inherits, instance, ...);
         if (not descriptor.constructor) then return; end
         descriptor.constructor(instance, select(2, ...));
      end

      -- Builds a class constructor
      function constructor(namespace, name, descriptor)
         return function(...)
            local instance = buildInstance(descriptor);
            instance.__name = name;
            instance.__type = descriptor;
            instance.__namespace = namespace;
            constructAll(descriptor, instance, ...);
            return instance;
         end
      end

      -- A namespace root that can have classes added to it
      local registration = namespace('', false);

      -- A namespace root that will return an executable constructor instead of a class
      local construction = namespace('', true);

      -- class & new
      return registration, construction;
   end

   class, new = createNS(); -- Adds the global class/new keys

   function class:NameSpace() return createNS(); end -- Exposes custom namespace scoping
end)();
