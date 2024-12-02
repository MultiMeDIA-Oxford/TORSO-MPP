function mklink( file )

  if isdir( file )
    odir = file;
    F = dir( odir ); F( strcmp( {F.name} , '.' ) | strcmp( {F.name} , '..' ) ) = [];
    for f = 1:numel(F)
      try
        file = F(f).name;
        [~,fn,e] = fileparts(file);
        if areDuplicates( file , which([fn,e]) )
          mklink( fullfile( odir , file ) );
        end
      end
    end
    
    return;
  end


  [p,fn,e] = fileparts( file );
  
  if isempty(p), p = pwd; end
  if isempty(e), e = '.m'; end
  
  fn = [ fn , e ];
  file = fullfile( p , fn );
  
  
  fn = which( fn );
  if isempty( fn )
    error('cannot found %s',fn);
  end
  
  if isfile( file )
    delete( file );
  end
  
  system( [ 'mklink  "' , file , '"  "' , fn , '"' ] );
  
  
end