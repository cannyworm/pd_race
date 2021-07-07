-- _table extension 
-- callback( value , key , _table )
desk = {}

desk.find = function ( _table , callback )
    for k , v in pairs(_table) do 
        if callback( v , k , _table ) == true then 
            return v , k
        end
    end
    return nil
end

desk.findv = function ( _table , v) 
    return desk.find( _table , function (_v) return _v == v end  ) 
end

desk.findk = function ( _table , k) 
    return desk.find( _table , function (_v , _k) return _k == k end  )
end

desk.map = function ( _table , callback) -- for _table
    local maps = {}
    for k , v in pairs(_table)  do
        desk.insert_end(maps,callback( v,k,_table))
    end
    return maps 
end

desk.imap = function ( _table , callback) -- for array
    local maps = {}
    for k , v in ipairs(_table)  do
        maps[k] = callback(v , k , _table)
    end
    return maps
end


desk.insert = function(_table , pos , v )
    table.insert(_table,pos,v)
    return pos , _table[pos]
end

desk.insert_beg = function ( _table , v)
    return 1 , _table[desk.insert(_table,1,v)]
end

desk.insert_end = function ( _table  , v)
    local pos = #_table + 1
    return pos , _table[desk.insert(_table,pos,v)]
end


