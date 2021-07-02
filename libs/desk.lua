local desk = {}

desk.find = function ( table , callback )
    for k , v in pairs(table) do 
        if callback( v , k , table ) == true then 
            return v , k
        end
    end
    return nil
end

desk.findv = function ( table , v) 
    return desk.find( table , function (_v) return _v == v end  ) 
end

desk.findk = function ( table , k) 
    return select( 2 , desk.find( table , function (_v , _k) return _k == k end  ) )
end



