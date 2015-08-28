dofile('test.lua');
dofile('../Source/ModCraft.lua');

test('Namespaces', function(ass)
   ass.truthy(class, 'Root NS');
   ass.truthy(class.NS, 'Dynamic NS');

   local descriptor = {};
   class.NS.test = descriptor;
   ass.truthy(descriptor == class.NS.test, 'Assignment Retrieval');

   class.Compound.NameSpace.test = descriptor;
   ass.truthy(descriptor == class.Compound.NameSpace.test, 'Compound Assignment');

   local instance = false;
   local param = false;
   class.superclass = {
      super = function(self)
         instance = self;
      end
   };
   class.subclass = {
      inherits = class.superclass,
      constructor = function(self, value)
         instance = self;
         param = value;
      end,
      sub = function(self)
         instance = self;
      end
   };

   local superinst = new:superclass();
   ass.truthy(superinst, 'No Constructor');
   ass.truthy(superinst.super == class.superclass.super, 'Inherits Self');
   ass.truthy(superinst.__type == class.superclass, 'Type Set');
   ass.truthy(superinst.__namespace == class, 'NameSpace Set');
   ass.truthy(superinst.__name == 'superclass', 'Name Set');
   instance = false;
   superinst:super();
   ass.truthy(instance == superinst, 'Super Invocation');

   instance = false;
   local subinst = new:subclass('value');
   ass.falsey(subinst == superinst, 'Unique');
   ass.truthy(instance == subinst, 'Constructor');
   ass.truthy(param == 'value', 'Parameter');
   ass.truthy(subinst.sub, 'Inherits Self');
   ass.truthy(subinst.super, 'Inherits Super');
   ass.truthy(subinst.__type == class.subclass, 'Type Set');
   ass.truthy(subinst.__namespace == class, 'NameSpace Set');
   ass.truthy(subinst.__name == 'subclass', 'Name Set');
   instance = false;
   subinst:super();
   ass.truthy(instance == subinst, 'Super Invocation');
   instance = false;
   subinst:sub();
   ass.truthy(instance == subinst, 'Sub Invocation');

   print(subinst.__name);

end);
