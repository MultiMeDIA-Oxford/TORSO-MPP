function SSM_explorer( F ,varargin)

  Cbb = repmat( { [-1,1]*3.3 } ,1,6 );
  Cbb = ndmat( Cbb{:} );

  bb = [ Inf , Inf , Inf ; -Inf , -Inf , -Inf ];
  for r = 1:size(Cbb,1)
    S = F( Cbb(r,:).' );
    try, S = MeshAppend( S ); end
    try, S = S.xyz; end
    S(:,end+1:3) = 0;
    bb = [ min( [ bb(1,:) ; S ] ,[],1) ; max( [ bb(2,:) ; S ] ,[],1) ];
  end
  
  
  tit = 'SSM explorer';
  in = inputname(1);
  if ~isempty(in), tit = [ tit , ': ' , in ]; end
  figure('NumberTitle','off','Name',tit,'Color','w');
  
  
  S0 = F(0);
  if isstruct( S0 )
    hS = patch('vertices',[],'Faces',S0.tri,'FaceColor',[0.6,0.75,0.75],'EdgeColor',[1 1 1]*0.2,varargin{:});
    try,  headlight;
    catch, camlight;
    end
    setS = @(S)set(hS,'Vertices',S.xyz);
  elseif isnumeric( S0 )
    if size(S0,2) == 3
      hS = line( S0(:,1) , S0(:,2) , S0(:,3) , 'Color','r','LineWidth',1,'Marker','o','MarkerSize',4,'MarkerEdgeColor','k','MarkerFaceColor','b',varargin{:});
      setS = @(S)set(hS,'XData',S(:,1),'YData',S(:,2),'ZData',S(:,3));
    elseif size(S0,2) == 2
      hS = line( S0(:,1) , S0(:,2) , 'Color','r','LineWidth',1,'Marker','o','MarkerSize',4,'MarkerEdgeColor','k','MarkerFaceColor','b',varargin{:});
      setS = @(S)set(hS,'XData',S(:,1),'YData',S(:,2));
    end
  elseif iscell( S0 )
    for s = 1:numel(S0)
      hS(s) = patch('vertices',[],'Faces',S0{s}.tri,'FaceColor',colorith(s),'EdgeColor',[1 1 1]*0.2,varargin{:});
    end
    try,  headlight;
    catch, camlight;
    end
    setS = @(S)arrayfun( @(s)set(hS(s),'Vertices',S{s}.xyz) , 1:numel(S) );
  end
  
  if diff(bb(:,3)) > 0
    view(3);
    axis( bb(1:6).' );
  else
    view(2);
    axis( bb(1:4).' );
  end
  set(gca,'DataAspectRatio',[1 1 1]);
  
  setS( F( [ 0 ; 0 ; 0 ; 0 ; 0 ] ) );

    P1 = eEntry( 'range', 3*[ -1 , 1 ],'ivalue', 0 ,'step', 0.1 ,'normal','position',[0 , 1+21*4 , 0 , 0] , 'slider2edit',@(x) sprintf('c(1): %g',x) );
    P2 = eEntry( 'range', 3*[ -1 , 1 ],'ivalue', 0 ,'step', 0.1 ,'normal','position',[0 , 1+21*3 , 0 , 0] , 'slider2edit',@(x) sprintf('c(2): %g',x) );
    P3 = eEntry( 'range', 3*[ -1 , 1 ],'ivalue', 0 ,'step', 0.1 ,'normal','position',[0 , 1+21*2 , 0 , 0] , 'slider2edit',@(x) sprintf('c(3): %g',x) );
    P4 = eEntry( 'range', 3*[ -1 , 1 ],'ivalue', 0 ,'step', 0.1 ,'normal','position',[0 , 1+21*1 , 0 , 0] , 'slider2edit',@(x) sprintf('c(4): %g',x) );
    P5 = eEntry( 'range', 3*[ -1 , 1 ],'ivalue', 0 ,'step', 0.1 ,'normal','position',[0 , 1+21*0 , 0 , 0] , 'slider2edit',@(x) sprintf('c(5): %g',x) );
    
%     uicontrol( 'Style','pushbutton','String','Copy command','Position',[ 5 , 10 + 21*5 , 80 , 20],'Callback',@(h,e)clipboard('copy',...
%       sprintf('BODY( %s )' , uneval([ P1.v , P2.v , P3.v , P4.v , P5.v ]) ))...
%       ,'ToolTipString','Copy the command to build this BUMP in the clipboard.');
    
    drawnow;
    P1.continuous = true; P1.callback_fcn = @(x)setS( F( [ P1.v ; P2.v ; P3.v ; P4.v ; P5.v ] ) );
    P2.continuous = true; P2.callback_fcn = @(x)setS( F( [ P1.v ; P2.v ; P3.v ; P4.v ; P5.v ] ) );
    P3.continuous = true; P3.callback_fcn = @(x)setS( F( [ P1.v ; P2.v ; P3.v ; P4.v ; P5.v ] ) );
    P4.continuous = true; P4.callback_fcn = @(x)setS( F( [ P1.v ; P2.v ; P3.v ; P4.v ; P5.v ] ) );
    P5.continuous = true; P5.callback_fcn = @(x)setS( F( [ P1.v ; P2.v ; P3.v ; P4.v ; P5.v ] ) );
    
  
end
