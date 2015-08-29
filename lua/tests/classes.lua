dofile('test.lua');
dofile('../Source/ModCraft.lua');

test('Namespaces', function(ass)
   ass.truthy(class, 'Root NS');
   ass.truthy(class.NS, 'Dynamic NS');
   ass.truthy(tostring(class.NS) == 'NS', 'NameSpace Path');
   ass.truthy(class.NS == class.NS, 'NameSpace Equality');
   ass.truthy('NS' == tostring(class.NS), 'String Equality');

   local descriptor = {value = {}};
   class.NS.test = descriptor;
   ass.truthy(descriptor.value == class.NS.test.value, 'Assignment Retrieval');

   class.Compound.NameSpace.test = descriptor;
   ass.truthy(descriptor.value == class.Compound.NameSpace.test.value, 'Compound Assignment');

   local constructor = function() end;
   class.NS.ctor = constructor;
   ass.truthy(class.NS.ctor.constructor == constructor, 'Constructor Assignment');

   ass.fails(function() new.x = {}; end, 'New Unassignable');
   ass.fails(function() class.NS.test.value = 1; end, 'Class Read Only');
   ass.truthy(class.NS.test.__name == 'NS.test', 'Class Name');
end);

test('Constructors', function(ass)
   local instance = false;
   local param = false;

   function class:FuncClass(p)
      instance = self;
      param = p;
   end

   local funcInst = new:FuncClass('test');
   ass.truthy(instance == funcInst, 'Instance OK');
   ass.truthy(param == 'test', 'Param OK');
   ass.truthy(funcInst.__type == class.FuncClass, 'Type OK');
   ass.truthy(funcInst.__namespace == class, 'NameSpace OK');
   ass.truthy(funcInst.__name == 'FuncClass', 'Name OK');
end);

test('Constructorless', function(ass)
   class.EmptyClass = {static = 'test'};
   local emptyInst = new:EmptyClass();

   ass.truthy(emptyInst.__type == class.EmptyClass, 'Type OK');
   ass.truthy(emptyInst.__namespace == class, 'NameSpace OK');
   ass.truthy(emptyInst.__name == 'EmptyClass', 'Name OK');
   ass.truthy((not emptyInst.constructor)
         and (not emptyInst.inherits)
         and (emptyInst.static == 'test'),
      'Static Fields OK');
end);

test('Inheritance', function(ass)
   local baseInst = false;
   local baseParam = false;
   function class:BaseClass(p)
      baseInst = self;
      baseParam = p;
      self.baseValue = 'base';
      self.override = 'base';
   end

   local parentInst = false;
   local parentParam1 = false;
   local parentParam2 = false;
   class.ParentClass = {
      inherits = class.BaseClass,
      constructor = function(self, p1, p2)
         parentInst = self;
         parentParam1 = p1;
         parentParam2 = p2;
         self.parentValue = 'parent';
         self.override = 'parent';
      end,
      parentStatic = 'parent',
      overrideStatic = 'parent'
   };

   local childInst = false;
   class.ChildClass = {
      inherits = class.ParentClass,
      constructor = function(self)
         childInst = self;
         self.childValue = 'child';
      end,
      childStatic = 'child',
      overrideStatic = 'child'
   };

   local instance = new:ChildClass('a', 'b');
   ass.truthy(instance == baseInst
      and instance == parentInst
      and instance == childInst,
      'Instance OK');
   ass.truthy(instance.__type == class.ChildClass, 'Type OK');
   ass.truthy(instance.__namespace == class, 'NameSpace OK');
   ass.truthy(instance.__name == 'ChildClass', 'Name OK');
   ass.truthy(instance.baseValue == 'base', 'Base Value OK');
   ass.truthy(baseParam == 'a', 'Base Param OK');
   ass.truthy(instance.parentValue == 'parent', 'Parent Value OK');
   ass.truthy(instance.parentStatic == 'parent', 'Parent Static OK');
   ass.truthy(parentParam1 == 'a', 'Parent Param1 OK');
   ass.truthy(parentParam2 == 'b', 'Parent Param2 OK');
   ass.truthy(instance.childValue == 'child', 'Child Value OK');
   ass.truthy(instance.childStatic == 'child', 'Child Static OK');
   ass.truthy(instance.override == 'parent', 'Override Value OK');
   ass.truthy(instance.overrideStatic == 'child', 'Override Static OK');
end);
