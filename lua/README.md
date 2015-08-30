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
var app = ModCraft.start();
class.service = {};
app.register.dependency.singleton('dependency', class.service);

// OR

ModCraft.register.dependency('dependency', ['application', function(app) {
  app.register.dependency.transient('dependency', function() {});
}]);
```

You can also access the dependency scope for the application directly as by requesting it as a dependency
```javascript
ModCraft.register.service('service', ['dependencies', function(scope) {
  var manualResolution = scope.resolve('some-other-service');
}]);
```
**Registration Method Signatures**

When using any of the registration methods you have a variety of signatures available

When registering an instance you can specify one or more names along with the object:
* ('name', {})
* (['name1', 'name2'], {})

When registering anything else you can use any one of the following signatures:
* ('name', function() {})
* ('name', ['dependency'], function(dependency) {})
* ('name', ['dependency', function(dependency) {}])
* (['name1', 'name2'], function() {})
* (['name1', 'name2'], ['dependency'], function(dependency) {})
* (['name1', 'name2'], ['dependency', function(dependency) {}])

**Registering The Same Name**

You can register more than one constructor or object to the same name and when resolved you will
be given an array with each dependency that was registered.

**Manual Resolution**

You can pre-resolve dependencies prior to startup using one of the following signatures:
* ModCraft.resolve('dependency-name'); // resolves the service by name
* ModCraft.resolve('dependency-name', {overrideValue: 'test'}); // overrides a dependency for this resolution
* ModCraft.resolve(['dependency1', 'dependency2'], function(dep1, dep2) {}); // constructs an object with the given requirements
* ModCraft.resolve(['dependency1', 'dependency2', function(dep1, dep2) {}]); // constructs an object with the given requirements
* ModCraft.resolve(['dependency1', 'dependency2'], function(dep1, dep2) {}, { dependency2: 'test' }); // constructs an object and overrides a dependency
* ModCraft.resolve(['dependency1', 'dependency2', function(dep1, dep2) {}, { dependency1: 'test' }); // constructs an object and overrides a dependency

You can resolve dependencies after startup with the .resolve() method located on the application instance
or the dependency scope (see registration above).

**Hosting Multiple Application Instances**

ModCraft.start() is a shortcut for
```javascript
var application = new ModCraft.Application();
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

```javascript
var application = new ModCraft.Application();
application.register.module('my-module', function() {
   // Other applications will not have this module registered...
});
```

After the .start() method has been called on an application you can still register
dependencies *(app.register.dependency, app.register.dependency.instance, etc...)*
but can no longer register modules or services.
