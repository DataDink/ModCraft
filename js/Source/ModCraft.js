/*************************************************************************
*  ModCraft.js
*  By DataDink
*
*  Source & Docs: https://www.github.com/DataDink/ModCraft
*  Support: IE9+, Chrome, Firefox, Opera, Safari
*  License: MIT
*************************************************************************/

// create: var application = new ModCraft(new ModCraft.DependencyResolver());
// register a service: application.register.singleton('name', ['dependencies', function() {}]);
// resolve a service: application.resolve('name');
var ModCraft = function(injector) {
   Object.defineProperty(this, 'register', {configurable: false, enumerable: true, value: injector.register });
   Object.defineProperty(this, 'resolve', {configurable: false, enumerable: true, value: injector.resolve });
};
