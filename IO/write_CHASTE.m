function M = write_CHASTE( H , name , format )
% 

  if nargin < 3
    format = 'ascii';
  end
  
  
  

  data = ( 0:size( H.tri,1)-1 ).';
  data = [ data , H.tri-1 ];
  for f = fieldnames( H ).'
    if  strcmp(  f{1} , 'tri'     ), continue; end
    if ~strncmp( f{1} , 'tri' , 3 ), continue; end
    data = [ data , H.(f{1}) ];
  end
  data = data.';

  fid = fopen([name '.ele'],'w');
  if strcmpi( format , 'ascii' )
    fprintf( fid , '%d %d %d\n' , size( data , 2 ) , size( H.tri,2) , size( data , 1 ) - 1 - size( H.tri,2) );
    str = repmat( '%d ' , 1 , size( data , 1 ) );
    str = [ str(1:end-1) , '\n' ];
    fprintf( fid , str , data );
  else
    error('not implemented yet... call to Aurore');
    fprintf( fid , '%d %d %d    BIN\n' , size( data , 1 ) , size( H.tri,2) , size( data , 2 ) - 1 - size( H.tri,2) );
    fwrite( fid , data );
  end
  fclose( fid );
  
  

  
  
  data = ( 0:size( H.xyz,1)-1 ).';
  data = [ data , double( H.xyz ) ];
  for f = fieldnames( H ).'
    if  strcmp(  f{1} , 'xyz'     ), continue; end
    if ~strncmp( f{1} , 'xyz' , 3 ), continue; end
    data = [ data , double( H.(f{1}) ) ];
  end
  data = data.';
  
  
  fid = fopen([name '.node'],'w');
  
  if strcmpi( format , 'ascii' )
    fprintf( fid , '%d %d %d %d\n' , size( data ,2) , size( H.xyz ,2) , size( data ,1) - 1 - size( H.xyz,2) , 0 );
    str = repmat( '%0.16e ' , 1 , size( data , 1 )-1 );
    str = [ '%d ' , str(1:end-1) , '\n' ];
    fprintf( fid , str , data );
  else
    error('not implemented yet... call to Aurore');
    
  end
  fclose( fid );


  if ~isfield( H , 'face' )
    %compute the surface indexes.
  end
  
  
  if isfield( H , 'face' )
    data = ( 0:size( H.face,1)-1 ).';
    data = [ data , H.face-1 ];
    data = data.';

    fid = fopen([name '.face'],'w');

    fprintf(fid,'%d 0 \n',size( data , 2) );
    fprintf(fid,'%d %d %d %d\n' , data );
  
    fclose( fid );
  end
  
  
  if isfield( H , 'epi' )
    fid=fopen([name '.epi'],'w');
    
    fprintf(fid,'%d\n' , (H.epi-1) );
    
    fclose(fid);
  end
  

  if isfield( H , 'lv' )
    fid=fopen([name '.lv'],'w');
    
    fprintf(fid,'%d\n' , (H.lv-1) );
    
    fclose(fid);
  end
  
  
  if isfield( H , 'rv' )
    fid=fopen([name '.rv'],'w');
    
    fprintf(fid,'%d\n' , (H.rv-1) );
    
    fclose(fid);
  end
  
end
