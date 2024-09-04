function enum(classname, define)
   local meta = {
      __enum = true,
      __cname = classname,
      __define = define
   }

   local type = {}
   
   for _,v in pairs(define) do
      type[v[1]] = v[2]
   end
   
   return setmetatable(type, meta)
end
