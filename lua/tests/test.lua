function test(name, t)
   local context = {passes = 0, failures = 0};
   local results = {};
   local write = function(message) table.insert(results, message); end

   context.truthy = function(value, message)
      if (value) then
         write('pass : ' .. (message or ''));
         context.passes = context.passes + 1;
      else
         write('fail : ' .. (message or ''));
         context.failures = context.failures + 1;
      end
   end;
   context.falsey = function(value, message)
      return context.truthy(not value, message);
   end;
   context.fails = function(f, message)
      return context.falsey(pcall(f), message);
   end;
   context.succeeds = function(f, message)
      return context.truthy(pcall(f), message);
   end;
   local status, err = pcall(function() t(context); end);
   write = function() error('assertion attempted after test completion'); end

   print('----------------');
   print((name or ' Starting Tests '));
   print('----------------');

   for i in ipairs(results) do
      print(results[i]);
   end

   print('----------------');
   print('  Test Summary  ');
   print('----------------');
   print('Passes:     ' .. tostring(context.passes));
   print('Failures:   ' .. tostring(context.failures));
   if (status) then
      print('Total:      ' .. tostring(context.passes + context.failures));
   else
      print('Incomplete: ' .. tostring(err));
   end
   print('----------------');
   print();
end
