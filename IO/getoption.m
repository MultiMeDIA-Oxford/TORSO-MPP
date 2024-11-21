function V = getoption( G , K , def )

  persistent allGroups
  if isempty( allGroups ), allGroups = cell(0,3); end
  
  
  optsFile = [ prefdir(1) , filesep , 'userOPTIONS.ini' ];
  if nargin < 1
    V = optsFile;
    return;
  end
  
  
  optsFileProp = dir( optsFile );
  if isempty( optsFileProp )
    optsFileProp = struct('name','userOPTIONS.ini','date','01-Jan-1970 00:00:00','bytes',0,'isdir',false,'datenum',719529.0);
  end
  
  Gid = find( strcmp( G , allGroups(:,1) ) );
  if isempty( Gid )  
%     disp('empty Gid');
    Gid = size( allGroups , 1 ) + 1;
    allGroups{Gid,1} = G;
    allGroups{Gid,2} = struct();
    allGroups{Gid,3} = 0;
  end
  if allGroups{ Gid , 3 } < optsFileProp.datenum
%     disp('Reading');
    allGroups{Gid,2} = read_INI( optsFile , G );
    allGroups{Gid,3} = optsFileProp.datenum;
  end
  
  G = allGroups{Gid,2};
  if      nargin < 2
    V = G;
  elseif isfield( G , K )
    V = G.(K);
  elseif nargin > 2
    V = def;
  else
    V = [];
  end
  
end
