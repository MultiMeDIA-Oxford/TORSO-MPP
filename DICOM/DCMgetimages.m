function IMAGES = DCMgetimages( D , varargin )
%
% 
% 

  [varargin,withDATA] = parseargs(varargin,'withDATA','$FORCE$',{true,false} );

  IMAGES = struct([]);

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
            for i = 1:numel(IS),   I = IS{i}; INFO_I = INFO_Z; try, INFO_I = mergestruct( INFO_I , D.(P).(T).(R).(O).(Z).(I).INFO ); end
              try, INFO_I = mergestruct( INFO_I , D.(P).(T).(R).(O).(Z).(I).info ); end
              thisI = D.(P).(T).(R).(O).(Z).(I);
              thisI.INFO = INFO_I;
              thisI.LOCATIONS = { P T R O Z I };
              if withDATA
                if isfield( thisI , 'DATA' ) && ~isempty( thisI.DATA )
                  thisI.DATA = thisI.DATA;
                else
                  thisI.DATA = dicomread( thisI.info.Filename );
                end
              end
              IMAGES = catstruct( 1 , IMAGES , thisI );
            end
          end
        end
      end
    end
  end
  

end
function names = getFieldNames( S , str )
  names = fieldnames(S);
  names = names( strncmp( names , str , numel(str) ) );
end