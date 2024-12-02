function o = fileprintf( fname , varargin )

  o = false;

  if isempty( fname ), return; end
  
  if numel( varargin ) > 1
    str = sprintf( varargin{:} );
  else
    str = varargin{1};
  end
  
  if ischar( fname )
  
    if ~isempty(str) && str(end)==10, str(end)=[]; end
    if ~isempty(str)
      try
        fid = safe_fopen( fname , 'a'  , 500, 1000);
        fprintf(fid, '%s',str);
        fprintf(fid,'\n');
        fclose(fid);
      catch, try, fclose(fid); end; end
    end
    
  elseif isnumeric( fname ) && fname == 1
    
    fprintf( 1 , str );
    
  end

  o = true;
  
end
