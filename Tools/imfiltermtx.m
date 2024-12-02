function M = imfiltermtx( X , K , varargin )
%{

X = round( randn([220,220,5]) );
K = conndef(3,'minimal'); K(2,2,2) = 4;
K = round( randn(3,5,2) );

tic; M = imfiltermtx( X , K , 0 , 'valid' ,'conv'); toc
maxnorm( M*X(:) - vec( convn(X,K,'valid') ) )

tic; M = imfiltermtx( X , K , 0 , 'full' ,'conv'); toc
maxnorm( M*X(:) - vec( convn(X,K,'full') ) )

tic; M = imfiltermtx( X , K , 'replicate' , 'full' ,'conv'); toc
maxnorm( M*X(:) - vec( imfilter(X,K,'replicate' , 'full' ,'conv') ) )


tic; mtimes( M , X(:) ); toc
tic; imfilter( X , K , 'circular' , 'full' ); toc

maxnorm( M*X(:) - vec( imfilter(X,K,'circular','full') ) )



maxnorm( convn(X,K,'same') - imfilter(X,K,0,'conv') )

maxnorm( convn(X,K,'full') - imfilter(X,K,0,'conv','full') )


%}


%   try
%     %chequea a los argumentos sean correctos
%     kk = imfilter(1,1,varargin{:});
%   catch
%     error('incorrect syntax for imfilter');
%   end


  CC = 'corr';
  [varargin,CC] = parseargs( varargin , 'conv', '$FORCE$',{'conv',CC} );
  [varargin,CC] = parseargs( varargin , 'corr', '$FORCE$',{'corr',CC} );


  BM = 0;
  [varargin,BM] = parseargs( varargin , 'symmetric' , '$FORCE$',{'symmetric' ,BM} );
  [varargin,BM] = parseargs( varargin , 'circular'  , '$FORCE$',{'circular'  ,BM} );
  [varargin,BM] = parseargs( varargin , 'replicate' , '$FORCE$',{'replicate' ,BM} );

  
  SZ = 'same';
  [varargin,SZ] = parseargs( varargin , 'same'  , '$FORCE$',{'same'  ,SZ} );
  [varargin,SZ] = parseargs( varargin , 'full'  , '$FORCE$',{'full'  ,SZ} );
  [varargin,SZ] = parseargs( varargin , 'valid' , '$FORCE$',{'valid' ,SZ} );

  
  if ~isempty( varargin )
    if numel( varargin ) == 1 && isnumeric( varargin{1} )
      BM = varargin{1};
    else
      error('quedan cosas en varargin');
    end
  end
  
  
  if isnumeric( BM )  &&  ~( isnan( BM )  ||   BM == 0 )
    error('in case of padd the input with a number, it must be zero');
  end
    
  if iscell(X)
    szX = cell2mat( X );
  else
    szX = size(X); 
  end
  szK = size(K);
  
  szX( (end+1):max( numel(szX),numel(szK) ) ) = 1;
  szK( (end+1):max( numel(szX),numel(szK) ) ) = 1;

  if strcmp(CC,'conv')
    for d = find( szK > 1 ), K = flipdim(K,d); end
  end

  
  center = ceil( szK / 2 );
  switch SZ
    case 'same'
      X_idxs = arrayfun( @(d) (1:szX(d))-center(d) , 1:numel(szX) , 'UniformOutput', false );
    case 'valid'
      pads1 = ceil( szK/2 )-1;
      pads2 = floor( szK/2 );
      X_idxs = arrayfun( @(d) ( ( 1 + pads1(d) ):( szX(d) - pads2(d) ) ) - center(d) , 1:numel(szX) , 'UniformOutput', false );
    case 'full'
      pads1 = floor( szK/2 );
      pads2 = ceil( szK/2 )-1;
      X_idxs = arrayfun( @(d) ( ( 1 - pads1(d) ):( szX(d) + pads2(d) ) ) - center(d) , 1:numel(szX) , 'UniformOutput', false );
  end
  X_idxs = ndmat_mx( X_idxs{:} );

  
  Nx = prod(szX);
  Ny = size(X_idxs,1);

  
  Ks = find( K(:) );
  try
  JS = uninit( [ Ny * numel(Ks) , numel(szX) ] , 'int32'    );
  catch
  JS = zeros( [ Ny * numel(Ks) , numel(szX) ] , 'int32'    );
  end    

  for k = 1:numel(Ks)
    ids = bsxfun( @plus , X_idxs , ind2subv( szK , Ks(k) ) );
    JS( ( (k-1)*Ny+1 ):( k*Ny ) , : ) = ids;
  end

    valids = [];
  invalids = [];
  if isnumeric( BM ) && BM == 0
    valids = all( ( JS >= 1 )  &  bsxfun( @le , JS , szX ) , 2 );
    JS = JS( valids , : );
    JS = double( JS );
    
  elseif isnumeric( BM ) && isnan( BM )
    invalids = any( ( JS < 1 )  |  bsxfun( @gt , JS , szX ) , 2 );
    JS = double( JS );
    JS = bsxfun( @max , JS , 1   );
    JS = bsxfun( @min , JS , szX );

  elseif strcmp( BM , 'replicate' )
    JS = double( JS );
    JS = bsxfun( @max , JS , 1   );
    JS = bsxfun( @min , JS , szX );
    
  elseif strcmp( BM , 'circular' )
    JS = double( JS );
    JS = JS - 1;
    JS = bsxfun( @mod , JS , szX );
    JS = JS + 1;
    
  elseif strcmp( BM , 'symmetric' )
    JS = double( JS );
    for k = 1:size(JS,2)
      mi = -min( JS(:,k) ) + 1;
      ma =  max( JS(:,k) ) - szX(k) + 1;

      s = padding( 1:szX(k) , [0 mi;0 ma] , 'symmetric' );
      
      JS(:,k) = s( JS(:,k) + mi );
    end

  else
    error('incorrect boundary mode');
  end

  
  IS = bsxfun( @plus , (1:Ny).' , zeros(1,numel(Ks)) );
  IS = IS(:);
  if ~isempty( valids )
    IS = IS( valids );
  end

  
  VS = ones(Ny,1) *  vec( K( Ks ) ).';
  VS = VS(:);
  if ~isempty( invalids )
    VS( invalids ) = NaN;
  end
  if ~isempty( valids )
    VS = VS( valids );
  end
  if ~islogical( VS )   &&  ~isa( VS , 'double' )
    VS = double( VS );
  end

  JS = sub2indv( szX , JS );

  M = sparse( IS , JS , VS , Ny , Nx );
%   if ~isempty( invalids )
%     M( any( isnan( M ) , 2 ) , : ) = 0;
%   end


%   X(:) = 1:numel(X);
%   
%   K0 = zeros( size(K) );
%   
%   
% %   M = sparse(0);
%   M = sparse([],[],[],numel(X),numel(X), numel(X)*nnz(K) );
%   
%   for k = find( K(:) ).'
%     K0(k) = 1;
%     
%     Js = fconvn( X , K0 , varargin{:} );
%     Js = round( Js(:) );
%     
% %     Js = imfilter( X , K0 , varargin{:} );
%     
%     if ~any( Js ),  continue;  end
%     Is = find(Js);
%     Js = Js( ~~Js );
%     try
%       M = M + sparse( Is , Js , K(k) , numel(X) , numel(Js) );
%     catch
%       keyboard
%     end
%     
%     
%     K0(k) = 0;
%   end
  
end
