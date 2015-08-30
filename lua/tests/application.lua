dofile('test.lua');
dofile('../Source/ModCraft.lua');
dofile('../Source/DependencyResolver.lua');
dofile('../Source/Application.lua');

test('Readonly', function(ass)
   ass.truthy(type(ModCraft) == 'table', 'Global');
   ass.truthy(type(ModCraft.register) == 'table', 'Global');
   ass.truthy(type(ModCraft.register.module) == 'function', 'Global');
   ass.truthy(type(ModCraft.register.service) == 'function', 'Global');
   ass.truthy(type(ModCraft.register.dependency) == 'table', 'Global');
   ass.truthy(type(ModCraft.register.dependency.instance) == 'function', 'Global');
   ass.truthy(type(ModCraft.register.dependency.singleton) == 'function', 'Global');
   ass.truthy(type(ModCraft.register.dependency.contextual) == 'function', 'Global');
   ass.truthy(type(ModCraft.register.dependency.transient) == 'function', 'Global');
   ass.truthy(type(ModCraft.resolve) == 'function', 'Global');

   ass.fails(function() ModCraft.x = nil; end, 'ModCraft');
   ass.fails(function() ModCraft.register.x = nil; end, 'ModCraft.register');
   ass.fails(function() ModCraft.register.dependency.x = nil; end, 'ModCraft.register.dependency');

   local application = ModCraft.start();
   ass.truthy(type(application.register) == 'table', 'Instance');
   ass.truthy(type(application.register.module) == 'function', 'Instance');
   ass.truthy(type(application.register.service) == 'function', 'Instance');
   ass.truthy(type(application.register.dependency) == 'table', 'Instance');
   ass.truthy(type(application.register.dependency.instance) == 'function', 'Instance');
   ass.truthy(type(application.register.dependency.singleton) == 'function', 'Instance');
   ass.truthy(type(application.register.dependency.contextual) == 'function', 'Instance');
   ass.truthy(type(application.register.dependency.transient) == 'function', 'Instance');
   ass.truthy(type(application.resolve) == 'function', 'Instance');

   ass.fails(function() application.x = nil; end, 'application');
   ass.fails(function() application.register.x = nil; end, 'application.register');
   ass.fails(function() application.register.dependency.x = nil; end, 'application.register.dependency');
end);

test('Modules', function(ass)
   local appSingle = new .ModCraft:Application();
   local init = false;
   local start = false;
   class .single = {
      init = function() init = true; end,
      start = function() start = true; end,
   }
   appSingle.register.module('inner', class.single);
   appSingle.start();
   ass.truthy(init, 'Single Init');
   ass.truthy(start, 'Single Start');

   local appMultiple = new .ModCraft.Application();
   local firstInit = false;
   local firstStart = false;
   local secondInit = false;
   local secondStart = false;
   init = false;
   start = false;
   class .first = {
      start = function() firstStart = true; end
   };
   class .second = {
      init = function() secondInit = true; end,
   };
   appMultiple.register.module('first', class.first);
   appMultiple.register.module('second', class.second);
   appMultiple.start();
   ass.falsey(init or start, 'Scope');
   ass.truthy(firstStart and secondInit, 'Multiple Modules');
   ass.falsey(firstInit or secondStart, 'Optional Stages');

   ass.fails(function() appMultiple.start() end, 'Start Frozen');
   ass.fails(function() appMultiple.register.module('test', class.single) end, 'Module Frozen');
   ass.fails(function() appMultiple.register.service('test', class.single) end, 'Service Frozen');
end);

test('Scope', function(ass)
   local global = {};
   ModCraft.register.dependency.instance('global', global);
   ass.truthy(global == ModCraft.resolve('global'), 'Global Resolve');

   local application = new .ModCraft:Application();
   ass.truthy(global == application.resolve('global'), 'Instance Resolve');

   local scoped = {};
   application.register.dependency.instance('scoped', scoped);
   ass.truthy(scoped == application.resolve('scoped'), 'Instance Scope Resolve');
   ass.truthy(scoped ~= ModCraft.resolve('scoped'), 'Global Scope Resolve');
end);
