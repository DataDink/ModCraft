dofile('test.lua');
dofile('../Source/ModCraft.lua');
dofile('../Source/DependencyResolver.lua');

local resolver = new .ModCraft:DependencyResolver();
function class:RegTest() end
resolver.register.singleton('test', class.RegTest);


test('New', function(ass)
   ass.truthy(type(class.ModCraft.DependencyResolver) == 'table', 'Namespaced');
   ass.truthy(type(new.ModCraft.DependencyResolver) == 'function', 'Constructor');
   local instance = new .ModCraft:DependencyResolver();
   ass.truthy(instance.__type == class.ModCraft.DependencyResolver, 'Constructed');
   ass.fails(function()
      class.ModCraft.DependencyResolver.register = 'asdf';
   end, 'Is Read Only');
end);

test('Registration', function(ass)
   local resolver = new .ModCraft:DependencyResolver();
   ass.succeeds(function()
      resolver.register.instance('instance', {});
      resolver.register.instance({'instance', 'instance2'}, {});
   end, 'Registers Instance');

   function class:RegTest() end
   ass.succeeds(function()
      resolver.register.singleton('singleton', class.RegTest);
      resolver.register.contextual('contextual', class.RegTest);
      resolver.register.transient('transient', class.RegTest);
   end, 'Registers No Deps');
   ass.succeeds(function()
      resolver.register.singleton('singleton', {'item1'}, class.RegTest);
      resolver.register.contextual('contextual', {'item1'}, class.RegTest);
      resolver.register.transient('transient', {'item1'}, class.RegTest);
   end, 'Registers Separated Deps');
   ass.succeeds(function()
      resolver.register.singleton('singleton', {'item1', class.RegTest});
      resolver.register.contextual('contextual', {'item1', class.RegTest});
      resolver.register.transient('transient', {'item1', class.RegTest});
   end, 'Registers Combined Deps');
end);

test('Resolves', function(ass)
   local resolver = new .ModCraft:DependencyResolver();
   local inst = {version = 'instance'};
   resolver.register.instance('inst', inst);
   function class:single() self.version = 'singleton'; end
   resolver.register.singleton('single', class.single);
   function class:ctx() self.version = 'contextual'; end
   resolver.register.contextual('ctx', class.ctx);
   function class:trans() self.version = 'transient'; end
   resolver.register.transient('trans', class.trans);

   local instance = resolver.resolve('inst');
   ass.truthy(resolver.resolve('inst').version == 'instance', 'Instance Resolved');
   ass.truthy(resolver.resolve('single').version == 'singleton', 'Singleton Resolved');
   ass.truthy(resolver.resolve('ctx').version == 'contextual', 'Contextual Resolved');
   ass.truthy(resolver.resolve('trans').version == 'transient', 'Transient Resolved');
end);

test('Dependencies', function(ass)
   local resolver = new .ModCraft:DependencyResolver();

   function class:inner() self.x = 'inner'; end
   function class:parent(i) self.i = i; end
   function class:outer(p) self.p = p; end

   resolver.register.transient('inner', class.inner);
   resolver.register.transient('parent', {'inner', class.parent});
   resolver.register.transient('outer', {'parent'}, class.outer);

   local res = resolver.resolve('outer');
   ass.truthy(res.p.i.x == 'inner', 'Deps Filled');
end);

test('Lifetime', function(ass)
   local resolver = new .ModCraft:DependencyResolver();

   function class:singleTime() end;
   resolver.register.singleton('singleton', class.singleTime);
   ass.truthy(resolver.resolve('singleton') == resolver.resolve('singleton'), 'Singleton');

   function class:ctxTime() end;
   resolver.register.contextual('contextual', class.ctxTime);
   local inner = false;
   local outer = false;
   function class:innerTime(d) inner = d; end;
   function class:outerTime(d) outer = d; end;
   resolver.register.transient('inner', {'contextual', class.innerTime});
   resolver.register.transient('outer', {'contextual', 'inner', class.outerTime});
   resolver.resolve('outer');
   ass.truthy(inner == outer, 'Contextual');

   function class:transTime() end;
   resolver.register.transient('transient', class.transTime);
   local inner2 = false;
   local outer2 = false;
   function class:innerTrans(d) inner2 = d; end
   function class:outerTrans(d) outer2 = d; end
   resolver.register.transient('inner2', {'transient', class.innerTrans});
   resolver.register.transient('outer2', {'transient', 'inner2', class.outerTrans});
   resolver.resolve('outer2');
   ass.truthy(inner2 ~= outer2, 'Transient');
end);

test('Multiples', function(ass)
   local resolver = new .ModCraft:DependencyResolver();

   local instance = {};
   function class:a() end;
   resolver.register.instance('instance', instance);
   resolver.register.instance('instance', instance);
   local resolutions = resolver.resolve('instance');
   ass.truthy(#resolutions == 2, 'Counted');
   ass.truthy(resolutions[1] == resolutions[2], 'Matched');
   ass.truthy(resolutions[1] == instance, 'Typed');
end);
