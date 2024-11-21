function D = DCMselect( D , func )
%
% Runs over all the IMAGES (leafs of the DCM_tree and evaluates func on
% IMAGE.INFO (dicominfo), if this results false, remove the image from the
% DCM_tree. At the end remove all empty branches.
%
% Example:
%         DCMselect( DCMs , @(i)~isempty( dicomread( i.Filename ) ) )
%         DCMselect( DCMs , @(i)prod( i.zSize ) )
% 
% remove all the item which are not images.
% 
% 

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
              evalOK = false;
              if ~evalOK, try, RemoveIS(i) = ~feval( func , INFO_I , { P T R O Z I } ); evalOK = true;  end; end
              if ~evalOK, try, RemoveIS(i) = ~feval( func , INFO_I ); evalOK = true;                    end; end
              if ~evalOK, try,                feval( func , INFO_I , { P T R O Z I } ); evalOK = true;  end; end
              if ~evalOK, try,                feval( func , INFO_I ); evalOK = true;                    end; end
            end
            
            D.(P).(T).(R).(O).(Z) = rmfield( D.(P).(T).(R).(O).(Z) , IS( RemoveIS ) );
            if numel( getFieldNames( D.(P).(T).(R).(O).(Z) , 'IMAGE_' ) ) < 1, D.(P).(T).(R).(O) = rmfield( D.(P).(T).(R).(O) , Z ); end
          end
          if numel( getFieldNames( D.(P).(T).(R).(O) , 'Position_' ) ) < 1, D.(P).(T).(R) = rmfield( D.(P).(T).(R) , O ); end
        end
        if numel( getFieldNames( D.(P).(T).(R) , 'Orientation_' ) ) < 1, D.(P).(T) = rmfield( D.(P).(T) , R ); end
      end
      if numel( getFieldNames( D.(P).(T) , 'Serie_' ) ) < 1, D.(P) = rmfield( D.(P) , T ); end
    end
    if numel( getFieldNames( D.(P) , 'Study_' ) ) < 1, D = rmfield( D , P ); end
  end
  

  function names = getFieldNames( S , str )
    names = fieldnames(S);
    names = names( strncmp( names , str , numel(str) ) );
  end
end
