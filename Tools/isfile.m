function isf = isfile( fname , maxTime , maxTries )

  try
    isf = builtin( 'isfile' , fname );
    return;
  end


  isf = exist( fname , 'file' ) == 2;
  if isf || ( nargin > 1 && isequal( maxTime , 'fast' ) )
    return;
  end
  
  try
    ffname= fixname( fname );
    if ~isequal( fname , ffname )
      fname = ffname;
      isf = exist( fname , 'file' ) == 2;
      if isf, return; end
    end
  end

  
  if nargin < 2 || isempty( maxTime  ), maxTime =  1; end
  if nargin < 3 || isempty( maxTries ), maxTries = 5; end

  Ntries = 0; T0 = clock;
  while fast_etime( clock , T0 ) < maxTime  &&  Ntries < maxTries
    Ntries = Ntries + 1;
    
    fid = fopen( fname , 'r' );
    if fid > 0
      fclose(fid);
      isf = true; break;
    end
    
    if exist( fname , 'file' ) == 2
      isf = true; break;
    end
    
    files = dir( fname );
    files( [ files.isdir ] ) = [];
    if any( strcmp( { files.name } , fname ) )
      isf = true; break;
    end
      
    if ispc
      try, [out1,out2] = system( ['dir ' fileparts( fname ) ] ); end
    else
      try, [out1,out2] = system( ['ls  ' fileparts( fname ) ] ); end
    end
    
    %pause(0.1);
    T1 = clock;
    while fast_etime( clock , T1 ) < 0.1
    end
    
  end
  
  
  function t = fast_etime(t1,t0)
    t = 86400*(datenummx(t1(:,1:3)) - datenummx(t0(:,1:3))) + ...
        (t1(:,4:6) - t0(:,4:6))*[3600; 60; 1];
  end
  
end
