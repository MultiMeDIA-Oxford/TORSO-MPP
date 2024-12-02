function [hg_,eentryI,eentryJ,eentryK] = image3( I , varargin )

  [varargin,asPVAR ] = parseargs( varargin , 'pvar','$FORCE$',{true,false}  );
  
  if asPVAR
    if isempty( inputname(1) ), error('asPVAR requieres a named variable'); end
    I = pVAR( inputname(1) );
  end
  
  
  [varargin,i,FCN2 ] = parseargs( varargin , 'fcn'  );
  [varargin,i,lw   ] = parseargs( varargin , 'linewidth','$DEFS$', 1 );


  if iscell( I.data )
    I.data = -nan( [numel(I.X) numel(I.Y) numel(I.Z)] );
  end
  if isempty( I.data )
    I.data = -nan( [numel(I.X) numel(I.Y) numel(I.Z)] );
  end
%   if isa( I.data , 'parallel.gpu.GPUArray' )
%       I.data = gather( I.data );
%   end
  

    try, DX = dualVector( I.X ); catch, DX = nan; end
    try, DY = dualVector( I.Y ); catch, DY = nan; end
    try, DZ = dualVector( I.Z ); catch, DZ = nan; end
    OFFSET = - 0.1*min([ diff(DX(:)) ; diff(DY(:)) ; diff(DZ(:)) ]);

    at_end_show_contours = false;
    
    LS( I.LABELS( I.LABELS ~= 0 ) ) = 1;
    LS = find(LS);
    if isempty( LS )
      [hg,eentryI,eentryJ,eentryK] = image3( permute( I.data ,[1 2 3 5 4]) , 'x' , I.X , 'y', I.Y , 'z', I.Z , 'm' , I.SpatialTransform , ...
                   'FCN' , @( key , ijk , handle_group ) calling_fcn( key , ijk , handle_group ) , ...
                    varargin{:} );
    else
      [hg,eentryI,eentryJ,eentryK] = image3( permute( I.data ,[1 2 3 5 4]) , 'x' , I.X , 'y', I.Y , 'z', I.Z , 'm' , I.SpatialTransform , ...
                   'FCN' , @( key , ijk , handle_group ) ShowContours( key , ijk , handle_group ) , ...
                   'INFO', @(ijk,xyz) sprintf('L:%3d - %s', ...
                              I.LABELS(ijk(1),ijk(2),ijk(3)) , ...
                              iff( I.LABELS(ijk(1),ijk(2),ijk(3)) , ...
                                    I.LABELS_INFO( max(1,I.LABELS(ijk(1),ijk(2),ijk(3))) ).description , ...
                                    '' ) ), ...
                    varargin{:} );
      at_end_show_contours = true;
        
    end
    
    
%     bb = ndmat( DX([1 end]) , DY([1 end]) , DZ([1 end]) );
%     bb = transform( bb , I.SpatialTransform );
%     bb = [ min( bb , [] , 1 ) ; max( bb , [] , 1 ) ];
%     bb = [ mean( bb , 1) - 0.6*diff(bb,1) ; mean( bb , 1) + 0.6*diff(bb,1) ];
%     
%     set(gca,'xlim',bb(:,1),'ylim',bb(:,2),'zlim',bb(:,3));


    %lw = 1;
    for l = LS
      if l == 0, continue; end
      line( 'Parent' , hg ,'XData',NaN,'YData',NaN,'ZData',NaN,'Color',I.LABELS_INFO(l).color , ...
        'Tag','CONTOURS_I','UserData',l , 'linewidth' , lw , 'hittest', 'off');
      line( 'Parent' , hg ,'XData',NaN,'YData',NaN,'ZData',NaN,'Color',I.LABELS_INFO(l).color , ...
        'Tag','CONTOURS_J','UserData',l , 'linewidth' , lw , 'hittest', 'off');
      line( 'Parent' , hg ,'XData',NaN,'YData',NaN,'ZData',NaN,'Color',I.LABELS_INFO(l).color , ...
        'Tag','CONTOURS_K','UserData',l , 'linewidth' , lw , 'hittest', 'off');
    end
    
    
    if ~isempty( I.LANDMARKS )
      switch class( I.LANDMARKS )
        case 'double'
%           I.LANDMARKS = transform( I.LANDMARKS , I.SpatialTransform , 'inv' );
          N_LANDMARKS = size(I.LANDMARKS,1);
          
%           colors = colormap( jet( N_LANDMARKS ) );
          colors = jet( N_LANDMARKS );
          try, colors = colors( NTHrandperm( 0 , N_LANDMARKS ) , : ); end
%           colors(:,1) = 1;
%           colors(:,2) = 0;
          
          
          patch( 'Parent' , hg ,...
            'vertices', I.LANDMARKS , 'faces', ( 1:N_LANDMARKS ).' ,...
            'FaceVertexCData', colors ,'tag','LANDMARKS' , 'UserData' , colors ,...
            'marker','o','markerfacecolor','flat','markersize',15, 'hittest', 'off','markeredgecolor',[1,0,0]*0.95,'linewidth',2);

%           line( 'Parent' , hg ,...
%             'XData',I.LANDMARKS(:,1) ,...
%             'YData',I.LANDMARKS(:,2) ,...
%             'ZData',I.LANDMARKS(:,3) ,...
%             'Color', [0.5 0.5 0.5] , ...
%             'linestyle','none','marker','o','markerfacecolor',[1 0 0],'markersize',5, 'hittest', 'off');
      
      end
      
    end
    
    if ~isempty( I.MESHES )
      warning('there are MESHES y no las estoy dibujando!!!');
    end
              

  if    at_end_show_contours
    try, ShowContours( 'I' , round(size(I,1:3)/2) , hg ); end
    try, ShowContours( 'J' , round(size(I,1:3)/2) , hg ); end
    try, ShowContours( 'K' , round(size(I,1:3)/2) , hg ); end
  end

  if nargout > 0, hg_ = hg; end
  
  if ~ishold( ancestortool(hg,'axes') )  &&  size( I.data , 5 ) == 1
    colormap( ancestortool(hg,'axes') , gray );
  end
  
  function calling_fcn( key , ijk , handle_group )

    hLANDMARKS = findall(handle_group,'Tag','LANDMARKS');
    if ~isempty(hLANDMARKS) && ishandle( hLANDMARKS ) && ~isempty(ijk)
%       distancias = bsxfun(@minus, I.LANDMARKS , [ I.X(ijk(1)) , I.Y(ijk(2)) , I.Z(ijk(3)) ] );
%       distancias = min( abs( distancias ) , [] , 2 )/2;
%       distancias = exp( -distancias.^2 ); 
%       
%       colors = get( hLANDMARKS , 'UserData' );
%       set( hLANDMARKS , 'FaceVertexCData' , bsxfun( @times , colors , distancias ) + bsxfun(@times,[0.1 0.3 0],(1-distancias)) );

      distancias = bsxfun(@minus, I.LANDMARKS , [ I.X(ijk(1)) , I.Y(ijk(2)) , I.Z(ijk(3)) ] );
      distancias = bsxfun(@rdivide,distancias,[ nonans(mean(diff(I.X)),1) , nonans(mean(diff(I.Y)),1) , nonans(mean(diff(I.Z)),1) ] );
      distancias = min( abs( distancias ) , [] , 2 );
      xyz = I.LANDMARKS;
      xyz( distancias > 10 , : ) = NaN;
      set( hLANDMARKS , 'vertices' , xyz );
    
    end
    
    if ~isempty( FCN2 )
      feval( FCN2 , key , ijk , handle_group );
    end
    
  end
  
  function ShowContours( key , ijk , handle_group )

    calling_fcn( key , ijk , handle_group );

    switch key
      case 'I'
        hcs = findall(handle_group,'Tag','CONTOURS_I' );
        if isempty( ijk )
          set( hcs , 'Visible' , 'off' );
          return;
        end

        set( hcs , 'Visible' , 'on' );
        
        II = squeeze( I.LABELS(ijk(1),:,:) );
        Ls = get( hcs , 'UserData' );
        if iscell( Ls ), Ls = cell2mat( Ls(:)' ); end
        if ~isvector( II )
          for lab = Ls
            c = boundary( II == lab  , DY , DZ , OFFSET );
            set( hcs(Ls==lab) , 'XData',c(1,:)*0+I.X( ijk(1) ),'YData',c(1,:),'ZData',c(2,:) );
          end
        end

      case 'J'
        hcs = findall(handle_group,'Tag','CONTOURS_J' );
        if isempty( ijk )
          set( hcs , 'Visible' , 'off' );
          return;
        end

        set( hcs , 'Visible' , 'on' );
        
        II = squeeze( I.LABELS(:,ijk(2),:) );
        Ls = get( hcs , 'UserData' );
        if iscell( Ls ), Ls = cell2mat( Ls(:)' ); end
        if ~isvector( II )
          for lab = Ls
            c = boundary( II == lab  , DX , DZ , OFFSET );
            set( hcs(Ls==lab) , 'XData',c(1,:),'YData',c(1,:)*0+I.Y(ijk(2)),'ZData',c(2,:) );
          end
        end


      case 'K'
        hcs = findall(handle_group,'Tag','CONTOURS_K' );
        if isempty( ijk )
          set( hcs , 'Visible' , 'off' );
          return;
        end

        set( hcs , 'Visible' , 'on' );
        
        II = squeeze( I.LABELS(:,:,ijk(3)) );
        Ls = get( hcs , 'UserData' );
        if iscell( Ls ), Ls = cell2mat( Ls(:)' ); end
        if ~isvector( II )
          for lab = Ls
            c = boundary( II == lab  , DX , DY , OFFSET );
            set( hcs(Ls==lab) , 'XData',c(1,:),'YData',c(2,:),'ZData',c(1,:)*0+I.Z(ijk(3)) );
          end
        end
          
    end 
    
  end
  
  

end

