function M = ExportMontage( hFig , name , FCN )

% mppOption ExportHRs = false
  mppOption ExportHRs true
  
  if ~ExportHRs, return; end
    
  if nargin < 3, FCN = @()0; end
  if nargin < 2, name = ''; end

  AXs = findall( hFig , 'Type','axes','Tag','sliceAxe');

  pos = cell2mat( get( AXs , 'Position' ) )*eye(4,2);
  [~,~,pos(:,1)] = unique(pos(:,1));
  [~,~,pos(:,2)] = unique(pos(:,2));


  wh = getposition( AXs(1) , 'pixels' ); wh = wh(3:4);
  wh = round( wh*800/max(wh) );

  hF = figure( 'Position',[ 50 , 150 , wh + 100 ] ,'Color',[0,0,0]+1 );
  hA = axes( 'Parent',hF,'units','pixels','Position' ,[5 5 wh] );

  %%
  M = {};
  for a = 1:numel( AXs )
    delete( get( hA ,'Children') );
    for p = {'Color','DataAspectRatio','Layer','Visible','XLim','YLim','ZLim','WarpToFill','YDir','XDir','ZDir'}
      set( hA , p{1} , get( AXs(a) , p{1} ) );
    end
%     set( hA , 'Color',[1 1 1]*.5);
%     x = ndmat( get( hA , 'XLim' ) , get( hA , 'YLim' ) );
%     line( x(:,1) , x(:,2) , 'Marker','.','LineStyle','none','Color','k');
    set( hA , 'XTick' ,[],'YTick',[],'ZTick',[],'XColor','k','YColor','k','ZColor','k','LineWidth',1,'Visible','on','Box','on','Layer','top');
    
    
    
%     Hs = get( AXs(a) ,'Children');
    Hs = findall( AXs(a) , 'Parent',AXs(a),'Visible','on');
    Hs = flipud( Hs );
    for h = Hs(:).'
      set( h , 'Parent' , hA );
    end
    
    LW = findall( Hs , 'LineStyle','-','Type','line'); try, LW(:,2) = cell2mat( get( LW , 'LineWidth') ); end
    set( LW(:,1) , 'LineWidth' , 4 );
    
    MS = findall( Hs , 'LineStyle','none','Type','line'); try, MS(:,2) = cell2mat( get( MS , 'MarkerSize') ); end
    set( MS(:,1) , 'MarkerSize' , 6 );

    try, 
      FCN(); end
    
%     I = getframe( hF ); I = I.cdata;
    I = uint8( photoscreen( hF ) * 255 );
    
    set( Hs , 'Parent' , AXs(a) );
    try, arrayfun( @(i)set( LW(i,1) , 'LineWidth',LW(i,2) ) , 1:size(LW,1) ); end
    try, arrayfun( @(i)set( MS(i,1) , 'MarkerSize',MS(i,2) ) , 1:size(MS,1) ); end

    %I = crop( I , 0 , ~bsxfun(@eq,I,vec([ 249 , 5 , 5 ],3) ) );
    try, I = crop( I , 0 , I<255 ); end
    M{pos(a,1),pos(a,2)} = I;
  end
  delete( hF );
  M = flip( M.' ,1);

  w = cellfun('isempty',M);
  [M{w}] = deal( zeros( size(M{find(~w,1)}) , 'uint8')+128 );
  s = min( cellfun(@(I)size(I,1),M(:)) ); for m =1:numel(M), M{m} = M{m}(1:s,:,:); end
  s = min( cellfun(@(I)size(I,2),M(:)) ); for m =1:numel(M), M{m} = M{m}(:,1:s,:); end

  if isempty( name )
    %M = cell2mat(M);
  elseif isequal( name(end) , filesep )
    
  else
    [p,~,ext] = fileparts( name );
    if ~isdir(p), mkdir(p); end
    switch lower(ext)
      case '.png'
        try, imwrite( cell2mat(M) , name ); end
      otherwise
        imwrite( cell2mat(M) , name );
    end
  end
    
end
