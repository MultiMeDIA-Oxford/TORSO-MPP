function ssmExplorer( SSM ,varargin)

  J = numel( SSM );
  try
    nm  = size( SSM(1).xyzM ,3);
    for j = 1:J
      if size( SSM(j).xyzM ,3) ~= nm, error('different number of modes'); end
      m = SSM(j).xyzm;
      M = SSM(j).xyzM;
      sz = size( SSM(j).xyzm );
      if ~isequal( sz(1) , size( M , 1) ), error('inconsistent number of points'); end
      if ~isequal( sz(2) , size( M , 2) ), error('inconsistent nnsd'); end
      M = reshape( M , [ prod(sz) , numel(M)/prod(sz) ] );
      SSM(j).xyzfun = @(q) reshape( M(:,1:numel(q)+1)*[q(:);0] , sz ) + m;
    end
  catch
    error('invalid SSM specification');
  end
  
  Cbb = repmat( { [-1,1]*3.3 } ,1,6 );
  Cbb = ndmat( Cbb{:} );

  bb = [ Inf , Inf , Inf ; -Inf , -Inf , -Inf ];
  for r = 1:size(Cbb,1)
    for j = 1:J
      S = SSM(j).xyzfun( Cbb(r,:).' );
      S(:,end+1:3) = 0;
      bb = [ min( [ bb(1,:) ; S ] ,[],1) ; max( [ bb(2,:) ; S ] ,[],1) ];
    end
  end
  
  
  tit = 'ssmExplorer';
  in = inputname(1);
  if ~isempty(in), tit = [ tit , ': ' , in ]; end
  figure('NumberTitle','off','Name',tit,'Color','w');
  

  h = [];
  for j = 1:J
    S = Mesh( SSM(j).xyzfun( 0 ) , SSM(j) );
    
    pprops = { 'FaceColor' , colorith(j) , 'EdgeColor' , colorith(j)/2 };
    celltype = meshCelltype( S );
    if celltype == 1
      pprops = [ pprops , 'Marker','o','MarkerSize',12,'MarkerFaceColor', colorith(j) ];
    end
    
    h(j) = patch( 'vertices' , S.xyz , 'Faces' , S.tri , pprops{:} , varargin{:} );
%     if strcmp( get( h(j) , 'Marker' ) , 'o' )
%       set( h(j) , 'MarkerFaceColor', rand(1,3) );
%     end
  end
  
  if diff(bb(:,3)) > 0
    view(3);
    axis( bb(1:6).' );
  else
    view(2);
    axis( bb(1:4).' );
  end
  set(gca,'DataAspectRatio',[1 1 1]);
  
  
  setS = @(q)arrayfun( @(s)set( h(s) , 'vertices' , SSM(s).xyzfun(q) ) , 1:J );
  
  setS( [ 0 ; 0 ; 0 ; 0 ; 0 ] );

    P1 = eEntry( 'range', 5*[ -1 , 1 ],'ivalue', 0 ,'step', 0.1 ,'normal','position',[0 , 1+21*4 , 0 , 0] , 'slider2edit',@(x) sprintf('c(1): %g',x) );
    P2 = eEntry( 'range', 5*[ -1 , 1 ],'ivalue', 0 ,'step', 0.1 ,'normal','position',[0 , 1+21*3 , 0 , 0] , 'slider2edit',@(x) sprintf('c(2): %g',x) );
    P3 = eEntry( 'range', 5*[ -1 , 1 ],'ivalue', 0 ,'step', 0.1 ,'normal','position',[0 , 1+21*2 , 0 , 0] , 'slider2edit',@(x) sprintf('c(3): %g',x) );
    P4 = eEntry( 'range', 5*[ -1 , 1 ],'ivalue', 0 ,'step', 0.1 ,'normal','position',[0 , 1+21*1 , 0 , 0] , 'slider2edit',@(x) sprintf('c(4): %g',x) );
    P5 = eEntry( 'range', 5*[ -1 , 1 ],'ivalue', 0 ,'step', 0.1 ,'normal','position',[0 , 1+21*0 , 0 , 0] , 'slider2edit',@(x) sprintf('c(5): %g',x) );
    
    
    drawnow;
    P1.continuous = true; P1.callback_fcn = @(x)setS( [ P1.v ; P2.v ; P3.v ; P4.v ; P5.v ] );
    P2.continuous = true; P2.callback_fcn = @(x)setS( [ P1.v ; P2.v ; P3.v ; P4.v ; P5.v ] );
    P3.continuous = true; P3.callback_fcn = @(x)setS( [ P1.v ; P2.v ; P3.v ; P4.v ; P5.v ] );
    P4.continuous = true; P4.callback_fcn = @(x)setS( [ P1.v ; P2.v ; P3.v ; P4.v ; P5.v ] );
    P5.continuous = true; P5.callback_fcn = @(x)setS( [ P1.v ; P2.v ; P3.v ; P4.v ; P5.v ] );
    
  
end
