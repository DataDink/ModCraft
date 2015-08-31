# ModCraft.lua
The framework framework

____

This is the core application framework extracted from Curvy.
It allows me to create modular frameworks and applications and provides basic IOC
functionality.

Applications using ModCraft are built by creating Modules which will be assembled,
initialized, and loaded by the framework. Everything else is up to the developer.

# Quick Start
```lua
-- Register a service
function class:OutputService()
   self.write = function(message)
      print(message); -- or whatever
   end
end
ModCraft.register.service('output', class.OutputService);

-- Register a module:
function class:MyModule(output)
   -- Each module will first be initialized before any modules are started
   function self:init() output.write('My App is being initialized.'); end
   -- Once all modules have been initialized they will be started
   function self:start() output.write('My App has now been started!'); end
end
ModCraft.register.module('my-app', {'output', class.MyModule});

// Now that all the pieces have been added we can start the application:
ModCraft.start();
```

# Documentation

**Lua Classes**

*note: static members do not work with the version of lua ComputerCraft is built on*

In order for ModCraft to work in lua there needs to be the concept of a class.
ModCraft brings with it a simple implementation of this.

ModCraft exposes two globals: "class" and "new". The class keyword
is used for defining classes and the new keyword is used for constructing them.

* Defining A Class

*Also see Defining Static Members below for the long-form version of a class*
```lua
function class :MyClass(value)
   self.instanceMethod = function()
      print('I can see value:', value);
   end
end
```

* Instantiating A Class
```lua
-- assuming you've previously defined MyClass
local instance = new :MyClass('test');
```

* Defining Static Members

You can also define static members on a class that will be given/shared
to instances of that class.
```lua
class .MyClass = {
   -- The constructor is a special member that will not be added to instances
   -- Specifying a constructor is optional
   constructor = function(self, value) print(value); end,

   -- This function will be shared between all instances of this class
   staticMethod = function()
      print("I don't have access to value because I'm static(ish)");
   end
}
```

* Inheriting Another Classes

Inheritance in this implementation is more like layering. Each constructor
starting with the most base class will be called with the same arguments.
Static members will by copied and overwrite each other in the same manner

```lua
function class :MyBase()
   print('my instance:', self);
end

class .MyClass = {
   -- The inherits member, like constructor, will not be added to instances
   inherits = class.MyBase,

   constructor = function(self)
      print('my instance:', self);
   end
}
```

* Namespacing Classes

You can also add a namespace to your class names like so:
```lua
class .ParentNamespace.ChildNamespace.MyClass = {};

-- OR

function class .ParentNamespace.ChildNamespace:MyClass() end;
```

These are accessed by the 'new' global in the same way
```lua
new .ParentNamespace.ChildNamespace:MyClass();
```

**Dependencies**

There are four types of dependencies:
* Instance: An object that has already been constructed can be registered as a dependency.
* Singleton: A constructor that will only be constructed the first time it is needed and recycled for all future dependencies.
* Contextual: A constructor that will be constructed once per resolution meaning it will only be recycled for children dependencies of dependencies.
* Transient: A constructor that will be re-constructed every time it is needed as a dependency.

**Pre-Startup Registration Methods**

The following registration methods are available prior to starting your application:
* ModCraft.register.dependency(): Registers a contextual dependency
* ModCraft.register.dependency.instance(): Registers an object as a dependency
* ModCraft.register.dependency.singleton(): Registers a singleton dependency
* ModCraft.register.dependency.transient(): Registers a transient dependency
* ModCraft.register.dependency.contextual(): Another way to register a contextual dependency
* ModCraft.register.service(): Another way to register a singleton dependency

To register a module you can use the following method:
* ModCraft.register.module()

The only difference between a module and a singleton is that a module will be loaded when ModCraft.start() is
called. When loaded ModCraft will look for and execute .init() and .start() methods on the module if they
are available.

**Post-Startup Registration Methods**

After the application has been started adding modules to your application is no longer available. You must use methods off either the application instance or dependency scope.

You can access the application instance either as a dependency or via the return value of the ModCraft.start()
function.

```lua
local app = ModCraft.start();
function class:service() end;
app.register.dependency.singleton('dependency', class.service);

-- OR
function class:dependency(app)
   app.register.dependency.instance('something-else', {});
end
ModCraft.register.dependency('dependency', {'application', class.dependency});
```

You can also access the dependency scope for the application directly as by requesting it as a dependency named "dependencies".
```lua
function class:MyService(scope)
   local manualResolve = scope.resolve('some-other-service');
end
ModCraft.register.service('service', {'dependencies', class.MyService});
```

**Registration Method Signatures**

When using any of the registration methods you have a variety of signatures available

When registering an instance you can specify one or more names along with the object:
* ('name', {})
* ({'name1', 'name2'}, {})

When registering anything else you can use any one of the following signatures:
* ('name', class.MyClass)
* ('name', {'dependency'}, class.MyClass)
* ('name', {'dependency', class.MyClass})
* ({'name1', 'name2'}, class.MyClass)
* ({'name1', 'name2'}, {'dependency'}, class.MyClass)
* ({'name1', 'name2'}, {'dependency', class.MyClass})

**Registering The Same Name**

You can register more than one constructor or object to the same name and when resolved you will
be given an array with each dependency that was registered.

**Manual Resolution**

You can pre-resolve dependencies prior to startup using one of the following signatures:
* ModCraft.resolve('dependency-name'); -- resolves the service by name
* ModCraft.resolve('dependency-name', {overrideValue = 'test'}); -- overrides a dependency for this resolution
* ModCraft.resolve({'dependency1', 'dependency2'}, class.MyClass); -- constructs an object with the given requirements
* ModCraft.resolve({'dependency1', 'dependency2', class.MyClass}); -- constructs an object with the given requirements
* ModCraft.resolve({'dependency1', 'dependency2'}, class.MyClass, { dependency2 = 'test' }); -- constructs an object and overrides a dependency
* ModCraft.resolve({'dependency1', 'dependency2', class.MyClass}, { dependency1 = 'test' }); -- constructs an object and overrides a dependency

You can resolve dependencies after startup with the .resolve() method located on the application instance
or the dependency scope (see registration above).

**Hosting Multiple Application Instances**

ModCraft.start() is a shortcut for
```lua
local application = new .ModCraft:Application();
application.start();
```

Each new ModCraft.Application branches off of the global dependency scope and becomes
its own environment. If you need to host multiple application environments you
can still add all of your common dependencies to the global registry prior to
instantiating a new application, but should add dependencies and modules specific
to your application after creating a new ModCraft.Application.

An application instance can have modules and services added to it until the
application.start() method is called. Adding modules and services to an application
instance is similar to the global registry except that you will us the .register
structure on the application instance.

```lua
local application = new .ModCraft:Application();
application.register.module('my-module', class.MyClass);
```

After the .start() method has been called on an application you can still register
dependencies *(app.register.dependency, app.register.dependency.instance, etc...)*
but can no longer register modules or services.
