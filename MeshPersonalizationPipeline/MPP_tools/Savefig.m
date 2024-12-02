function Savefig( hf , fn , cl )

  mppOption SAVE_FIGURES  true

  if nargin < 3, cl = true; end
  if nargin < 2, fn = []; end
  if nargin < 1, hf = []; end
  
  if isempty( hf ), hf = gcf; end
  
if SAVE_FIGURES

  fprintf('Saving figure ...\n' );


  SUBJECT_DIR = evalin( 'caller' , 'SUBJECT_DIR' );
  if ~isdir( fullfile( SUBJECT_DIR , 'mpp' ) )
    mkdir( fullfile( SUBJECT_DIR , 'mpp' ) );
  end
  
  if isempty( fn )
    fn = evalin( 'caller' , 'WHERE_AM_I' );
  end
  

  fn = fullfile( SUBJECT_DIR , 'mpp' , fn );
  fn = [ fn , '.fig' ];
  
  drawnow();
  
  %if cl
    delete( findall( hf ,'Visible','off','-not','Type','axes') );
    set( hf ,'ResizeFcn'             ,[]);
    set( hf ,'WindowButtonMotionFcn' ,[]);
    set( hf ,'WindowKeyReleaseFcn'   ,[]);
    set( hf ,'ApplicationData'       ,struct());
    for h = findall( hf ).'
      try, rmappdata( h ,'il3d'); end
      try, rmappdata( h ,'r'); end
      try, rmappdata( h ,'s'); end
      try, rmappdata( h ,'r_values'); end
      try, rmappdata( h ,'s_values'); end
      try, rmappdata( h ,'cline'); end
      try, rmappdata( h ,'Listener'); end
      try, rmappdata( h ,'LIMS'); end
      try, set(h,'ButtonDownFcn',[]); end
%       try, set(h,'DeleteFcn',[]); end
%       try, set(h,'CreateFcn',[]); end
%       try, set(h,'XDataSource',[]); end
%       try, set(h,'YDataSource',[]); end
%       try, set(h,'ZDataSource',[]); end
    end
    
%     ND = {};
%     for h = findall( hf ).'
%       kk = getnondefault( h );
%       ND = [ ND ; kk(1:2:end).' ];
%     end
  %end
  
  savefig( hf , fn );
  fprintf('Figure saved in file "%s"\n', fn );
  
end
  
  
  if cl
    close( hf );
    try, delete( hf); end
    drawnow;
    fprintf('Figure closed.\n');
  end
  
  
end

