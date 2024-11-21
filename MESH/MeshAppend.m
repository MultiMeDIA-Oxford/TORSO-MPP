function A = MeshAppend( varargin )
%
% m= AppendMeshes( m1 , m2 )
%

%%correct the celltype

  keepPARTS = false;
  if numel(varargin) && ( islogical( varargin{end} ) || ischar( varargin{end} ) )
    keepPARTS = varargin{end}; varargin(end) = [];
    if islogical( keepPARTS ) && numel( keepPARTS ) == 1
    elseif ischar( keepPARTS )
      switch lower( keepPARTS )
        case {'keepparts','kp','keep'}, keepPARTS = true;
        case {'removeparts','rm','remove'}, keepPARTS = false;
        otherwise, error('invalid specification of what to do with PARTS.');
      end
    else
      error('unknown specification of what to do with PARTS.');
    end
  end
    

  if numel( varargin ) && iscell( varargin{1} )
    A = MeshAppend( varargin{1}{:} , keepPARTS );
    return;
  end

  A = struct('xyz',[],'tri',[],'celltype',[],'xyzPART',[],'triPART',[]);
  %A = struct('xyz',[],'tri',[],'celltype',[]);

  for v = 1:numel(varargin)
    
    B = varargin{v};
    if isempty( B ), continue; end
    if ~isstruct( B ), error('only meshes are accepted as input'); end
    
    B.celltype = meshCelltype( B );
    if numel( B.celltype ) == 1
      B.celltype( 1:size(B.tri,1) , 1 ) = B.celltype;
    end
    
    B.xyzPART( 1:size(B.xyz,1) ,1) = v;
    B.triPART( 1:size(B.tri,1) ,1) = v;
    
    if isfield( B , 'uv' ) && isfield( B , 'texture' )
      if ~isfield( A , 'uv' ),      A.uv = zeros( size(A.xyz,1) , size(B.uv,2) ) + 1; end
      if ~isfield( A , 'texture' ), A.texture = uint8(zeros(0,0,3)); end
    end
    if isfield( A , 'uv' ) && isfield( A , 'texture' )
      if ~isfield( B , 'uv' ),      B.uv = zeros( size(B.xyz,1) , size(A.uv,2) ); end
      if ~isfield( B , 'texture' ), B.texture = uint8(cat(3,255,0,0)); end
    end
    
    
    for f = fieldnames( B ).', f = f{1};
      if strcmp( f , 'celltype' )
        A.celltype = [ A.celltype ; B.celltype ];
        continue;
      end
      
      if strcmp( f , 'xyz' ), continue; end
      if strncmp( f , 'xyz' , 3 )
        if ~isfield( A , f )
          sz = size( B.(f) ); sz(1) = size( A.xyz , 1 );
          A.(f) = NaN( sz );
        end
        A.(f) = [ A.(f) ; B.(f) ];
        continue;
      end
      
      if strcmp( f , 'tri' ), continue; end
      if strncmp( f , 'tri' , 3 )
        if ~isfield( A , f )
          sz = size( B.(f) ); sz(1) = size( A.tri , 1 );
          A.(f) = NaN( sz );
        end
        A.(f) = [ A.(f) ; B.(f) ];
        continue;
      end
      
      if strcmp( f , 'uv' )
        B.uv(:,2) = 1 - B.uv(:,2);
        B.uv = bsxfun( @times , B.uv , [ size( B.texture ,2) , size( B.texture ,1) ] - 1 );
        B.uv = B.uv + 1;
        %imagesc( B.texture ); hplotMESH( Mesh(B.uv,B.tri) ,'nf','EdgeColor','g','patch','marker','.' ); axis('equal');
        B.uv(:,1) = B.uv(:,1) + size( A.texture ,2);
        A.uv = [ A.uv ; B.uv ];
        continue;
      end
      
      if strcmp( f , 'texture' )
%         if ~isempty( A.texture )
          A.texture( end+1:size( B.texture ,1) ,:,:) = 60 + round(rand(1)*100);
%         end
%         if ~isempty( B.texture )
          B.texture( end+1:size( A.texture ,1) ,:,:) = 60 + round(rand(1)*100);
%         end
        
        A.texture = [ A.texture , B.texture ];
        %imagesc( A.texture ); hplot3d( A.uv , '.' )
        continue;
      end
      
    end
    
    A.tri( 1:end , end+1:size(B.tri,2) ) = 0;
    B.tri( 1:end , end+1:size(A.tri,2) ) = 0;
    w = B.tri == 0;
    w = numel( A.tri ) + find(w);
    
    A.tri = [ A.tri ; B.tri + size( A.xyz , 1 ) ];
    A.tri( w ) = 0;
    
    nTRI = size( A.tri ,1);
    
    
    A.xyz = [ A.xyz ; B.xyz ];                     nXYZ = size( A.xyz ,1);
    

    
    for f = fieldnames( A ).', f = f{1};
      if strcmp( f , 'tri' ), continue; end
      if strcmp( f , 'xyz' ), continue; end
      if strncmp( f , 'xyz' , 3 ) && size( A.(f) ,1 ) < nXYZ
        if iscell( A.(f) )
          [ A.(f){ end+1:nXYZ ,:,:,:,:} ] = deal(NaN);
        else
          A.(f)(end+1:nXYZ,:,:,:,:) = NaN;
        end
        continue;
      end
      if strncmp( f , 'tri' , 3 ) && size( A.(f) ,1 ) < nTRI
        if iscell( A.(f) )
          A.(f){nTRI,1} = [];
          [ A.(f){ end+1:nTRI ,:,:,:,:} ] = deal(NaN);
        else
          A.(f)(end+1:nTRI,:,:,:,:) = NaN;
        end
        continue;
      end
    end        
    
    
  end

  if ~isempty( A.xyz )
    if ~alleq( A.celltype )
      warning( 'celltypes look different');
    end
    A.celltype = A.celltype(1);
  end
  
  if isfield( A , 'uv' ) && isfield( A , 'texture' )
    A.uv = A.uv - 1;
    A.uv = bsxfun( @rdivide , A.uv , [ size( A.texture ,2) , size( A.texture ,1) ]-1 );
    A.uv(:,2) = 1 - A.uv(:,2);
  end

  
  if ~keepPARTS
    try, A = rmfield( A , 'xyzPART'); end
    try, A = rmfield( A , 'triPART'); end
  end
  
end
