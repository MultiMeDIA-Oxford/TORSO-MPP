function hNav = DCMexplorer_navigator( D , hNav , Idata , varargin )

  if nargin < 2
    hFig  = figure('NumberTitle', 'off',...
                   'IntegerHandle','off',...
                   'NextPlot','new',...
                   'Name','DCM Navigator',...
                   'Toolbar', 'none',...
                   'Menu','none',...
                   'Color',[1 1 1],...
                   'Position',[1180,70,530,530]);
    hAxe = axes('Parent',hFig,'Position',[0.1 0.1 0.8 0.8],'XColor',[1,0,0]*0.8,'YColor',[0,1,0]*0.8,'ZColor',[0,0,1]*0.8);
    hNav = hggroup('Parent',hAxe);
    axlim = [];
    
    D = DCMvalidate( D );

    INFO_ = struct(); try, INFO_ = D.INFO; end
    PS= getFieldNames( D , 'Patient_' );
    for p = 1:numel(PS),  P = PS{p}; INFO_P = INFO_; try, INFO_P = mergestruct( INFO_P , D.(P).INFO ); end
      TS = getFieldNames( D.(P) , 'Study_' );
      for t = 1:numel(TS),   T = TS{t}; INFO_T = INFO_P; try, INFO_T = mergestruct( INFO_T , D.(P).(T).INFO ); end
        RS = getFieldNames( D.(P).(T) , 'Serie_' );
        for r = 1:numel(RS),   R = RS{r}; INFO_R = INFO_T; try, INFO_R = mergestruct( INFO_R , D.(P).(T).(R).INFO ); end
          OS = getFieldNames( D.(P).(T).(R) , 'Orientation_' );
          for o = 1:numel(OS),   O = OS{o}; INFO_O = INFO_R; try, INFO_O = mergestruct( INFO_O , D.(P).(T).(R).(O).INFO ); end
            ZS = getFieldNames( D.(P).(T).(R).(O) , 'Position_' );
            for z = 1:numel(ZS),   Z = ZS{z}; INFO_Z = INFO_O; try, INFO_Z = mergestruct( INFO_Z , D.(P).(T).(R).(O).(Z).INFO ); end
              IS = getFieldNames( D.(P).(T).(R).(O).(Z) , 'IMAGE_' );
              RemoveIS = false( 1 , numel( IS ) );
              for i = 1:numel(IS),   I = IS{i}; INFO_I = INFO_Z; try, INFO_I = mergestruct( INFO_I , D.(P).(T).(R).(O).(Z).(I).INFO ); end
                try, INFO_I = mergestruct( INFO_I , D.(P).(T).(R).(O).(Z).(I).info ); end
                
                try
                  M = reshape( INFO_I.ImageOrientationPatient , 3 , 2 );
                  M(:,3)= cross( M(:,1), M(:,2) );
                  for cc = 1:3, for it = 1:5, M(:,cc) = M(:,cc)/sqrt( M(:,cc).' * M(:,cc) ); end; end

                  [xx,yy,zz] = ndgrid( [ 0 , double((INFO_I.Columns)-1)*INFO_I.PixelSpacing(1) ] ,...
                                       [ 0 , double((INFO_I.Rows   )-1)*INFO_I.PixelSpacing(2) ] ,...
                                         0 );
                  xyz = bsxfun( @plus , [ xx(:) , yy(:) , zz(:) ] * M.' , INFO_I.ImagePositionPatient(:).' );

                  axlim = [ min( [ axlim ; xyz ] , [] , 1 ) ; max( [ axlim ; xyz ] , [] , 1 ) ];

                  surface('Parent',hNav,...
                    'XData' , reshape( xyz(:,1) ,[2,2] ),...
                    'YData' , reshape( xyz(:,2) ,[2,2] ),...
                    'ZData' , reshape( xyz(:,3) ,[2,2] ),...
                    'EdgeColor',[1,1,1]*0.8,'LineWidth',1,'FaceColor','none',...
                    'Tag',INFO_I.MediaStorageSOPInstanceUID );
                end
              
              end
            end
          end
        end
      end
    end

    axlim = bsxfun( @plus , bsxfun( @minus , axlim , mean( axlim , 1 ) ) * 1.1 , mean( axlim , 1 ) );
    view( hAxe , 3 );
    set( hAxe , 'XLim' , axlim(:,1).' , 'YLim' , axlim(:,2).' , 'ZLim' , axlim(:,3).' );
    set( hAxe , 'DataAspectRatio',[1,1,1]);
    
    return;
  end

  
  
  set( findall(hNav,'Type','Surface') , 'EdgeColor',[1,1,1]*0.8,'LineWidth',1,'FaceColor','none','CData',[]);
  drawnow('expose')

  if isfield( D , 'MediaStorageSOPInstanceUID' )
    UIDs = { D.MediaStorageSOPInstanceUID };
  else
    UIDs = {};
    D = DCMvalidate( D );
    INFO_ = struct(); try, INFO_ = D.INFO; end
    PS= getFieldNames( D , 'Patient_' );
    for p = 1:numel(PS),  P = PS{p}; INFO_P = INFO_; try, INFO_P = mergestruct( INFO_P , D.(P).INFO ); end
      TS = getFieldNames( D.(P) , 'Study_' );
      for t = 1:numel(TS),   T = TS{t}; INFO_T = INFO_P; try, INFO_T = mergestruct( INFO_T , D.(P).(T).INFO ); end
        RS = getFieldNames( D.(P).(T) , 'Serie_' );
        for r = 1:numel(RS),   R = RS{r}; INFO_R = INFO_T; try, INFO_R = mergestruct( INFO_R , D.(P).(T).(R).INFO ); end
          OS = getFieldNames( D.(P).(T).(R) , 'Orientation_' );
          for o = 1:numel(OS),   O = OS{o}; INFO_O = INFO_R; try, INFO_O = mergestruct( INFO_O , D.(P).(T).(R).(O).INFO ); end
            ZS = getFieldNames( D.(P).(T).(R).(O) , 'Position_' );
            for z = 1:numel(ZS),   Z = ZS{z}; INFO_Z = INFO_O; try, INFO_Z = mergestruct( INFO_Z , D.(P).(T).(R).(O).(Z).INFO ); end
              IS = getFieldNames( D.(P).(T).(R).(O).(Z) , 'IMAGE_' );
              RemoveIS = false( 1 , numel( IS ) );
              for i = 1:numel(IS),   I = IS{i}; INFO_I = INFO_Z; try, INFO_I = mergestruct( INFO_I , D.(P).(T).(R).(O).(Z).(I).INFO ); end
                try, INFO_I = mergestruct( INFO_I , D.(P).(T).(R).(O).(Z).(I).info ); end
                
                try
                  UIDs{end+1,1} = INFO_I.MediaStorageSOPInstanceUID;
                end
              
              end
            end
          end
        end
      end
    end  
  end
  
  hS = [];
  for u = 1:numel( UIDs )
    hS = [ hS ; findall(hNav,'Type','Surface','Tag', UIDs{u} ) ];
  end
  if isempty( hS ), return; end
  
  set( hS , 'EdgeColor',[1,0,0],'LineWidth',2 );
  if numel( hS ) == 1
    try, set( hS , 'CData' , permute(Idata,[2 1 3:5]) , 'FaceColor','texture' ); end
  end
  
  
  
  drawnow('expose')

  
end
function names = getFieldNames( S , str )
  names = fieldnames(S);
  names = names( strncmp( names , str , numel(str) ) );
end
