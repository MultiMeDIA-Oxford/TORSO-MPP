function sz = filesize( fname , units )

  if nargin < 2
    units = 'bytes';
  end

  sz = -1;
  try
    
    fid = fopen( fname , 'r' );
    fseek( fid , 0 , 'eof' );
    sz = ftell( fid );
    fclose( fid );
    
  end

  if sz < 0 &&  isfile( fname )
    
    sz = dir( fname );
    sz = sz.bytes;
    
  end

  if sz < 0
    sz = -1;
    return;
  end

  switch lower(units)
    case {'bytes'},
    case {'bits'} , sz = sz*8;
    case {'k','kb','kbyte','kbytes','kilobyte','kilobytes','kilo','kilos'}, sz = sz/1024;
    case {'m','mb','mbyte','mbytes','megabyte','megabytes','mega','megas'}, sz = sz/1024/1024;
    case {'g','gb','gbyte','gbytes','gigabyte','gigabytes','giga','gigas'}, sz = sz/1024/1024/1024;
    case {'t','tb','tbyte','tbytes','terabyte','terabytes','tera','teras'}, sz = sz/1024/1024/1024/1024;
  end
  
end
