function D = DCMgroup( D )


  INFO_ = struct(); try, INFO_ = D.INFO; D = rmfield( D , 'INFO' ); end
  PS= getFieldNames( D , 'Patient_' );  cINFO_P = [];
  for p = 1:numel(PS),  P = PS{p}; INFO_P = INFO_; try, INFO_P = mergestruct( INFO_P , D.(P).INFO ); D.(P) = rmfield( D.(P) , 'INFO' ); end
    TS = getFieldNames( D.(P) , 'Study_' );  cINFO_T = [];
    for t = 1:numel(TS),   T = TS{t}; INFO_T = INFO_P; try, INFO_T = mergestruct( INFO_T , D.(P).(T).INFO ); D.(P).(T) = rmfield( D.(P).(T) , 'INFO' ); end
      RS = getFieldNames( D.(P).(T) , 'Serie_' );  cINFO_R = [];
      for r = 1:numel(RS),   R = RS{r}; INFO_R = INFO_T; try, INFO_R = mergestruct( INFO_R , D.(P).(T).(R).INFO ); D.(P).(T).(R) = rmfield( D.(P).(T).(R) , 'INFO' ); end
        OS = getFieldNames( D.(P).(T).(R) , 'Orientation_' );  cINFO_O = [];
        for o = 1:numel(OS),   O = OS{o}; INFO_O = INFO_R; try, INFO_O = mergestruct( INFO_O , D.(P).(T).(R).(O).INFO ); D.(P).(T).(R).(O) = rmfield( D.(P).(T).(R).(O) , 'INFO' ); end
          ZS = getFieldNames( D.(P).(T).(R).(O) , 'Position_' );  cINFO_Z = [];
          for z = 1:numel(ZS),   Z = ZS{z}; INFO_Z = INFO_O; try, INFO_Z = mergestruct( INFO_Z , D.(P).(T).(R).(O).(Z).INFO ); D.(P).(T).(R).(O).(Z) = rmfield( D.(P).(T).(R).(O).(Z) , 'INFO' ); end
            IS = getFieldNames( D.(P).(T).(R).(O).(Z) , 'IMAGE_' );  cINFO_I = [];
            for i = 1:numel(IS),   I = IS{i}; INFO_I = INFO_Z; try, INFO_I = mergestruct( INFO_I , D.(P).(T).(R).(O).(Z).(I).INFO ); D.(P).(T).(R).(O).(Z).(I) = rmfield( D.(P).(T).(R).(O).(Z).(I) , 'INFO' ); end
              try, INFO_I = mergestruct( INFO_I , D.(P).(T).(R).(O).(Z).(I).info ); end
              
              D.(P).(T).(R).(O).(Z).(I).INFO = INFO_I;
              D.(P).(T).(R).(O).(Z).(I).INFO = add_z_atts( D.(P).(T).(R).(O).(Z).(I).INFO , D.(P).(T).(R).(O).(Z).(I) );
            end


%   INFO_ = []; try, INFO_ = D.INFO; end
%   PS = getFieldNames( D , 'Patient_' );  cINFO_P = [];
%   for p = 1:numel(PS),  P= PS{p}; INFO_P = []; try, INFO_P = D.(P).INFO; end
%     
%     TS = getFieldNames( D.(P) , 'Study_' ); cINFO_T = [];
%     for t = 1:numel(TS),   T= TS{t}; INFO_T = []; try, INFO_T = D.(P).(T).INFO; end
% 
%       RS = getFieldNames( D.(P).(T) , 'Serie_' ); cINFO_R = [];
%       for r = 1:numel(RS),   R= RS{r}; INFO_R = []; try, INFO_R = D.(P).(T).(R).INFO; end
% 
%         OS = getFieldNames( D.(P).(T).(R) , 'Orientation_' ); cINFO_O = [];
%         for o = 1:numel(OS),   O= OS{o}; INFO_O = []; try, INFO_O = D.(P).(T).(R).(O).INFO; end
%         
%           ZS = getFieldNames( D.(P).(T).(R).(O) , 'Position_' ); cINFO_Z = [];
%           for z = 1:numel(ZS),    Z= ZS{z}; INFO_Z = []; try, INFO_Z = D.(P).(T).(R).(O).(Z).INFO; end
% 
%             IS = getFieldNames( D.(P).(T).(R).(O).(Z) , 'IMAGE_' ); cINFO_I = [];
%             for i = 1:numel(IS), I= IS{i};
%               if ~isfield( D.(P).(T).(R).(O).(Z).(I) , 'INFO' ) ||  isempty( D.(P).(T).(R).(O).(Z).(I).INFO )
%                 D.(P).(T).(R).(O).(Z).(I).INFO = D.(P).(T).(R).(O).(Z).(I).info;
%               end
%               D.(P).(T).(R).(O).(Z).(I).INFO = add_z_atts( D.(P).(T).(R).(O).(Z).(I).INFO , D.(P).(T).(R).(O).(Z).(I) );
%             end
            
            
            for i = 1:numel(IS), I= IS{i}; cINFO_I = remove_unequals( cINFO_I , D.(P).(T).(R).(O).(Z).(I).INFO ); end
            [ D.(P).(T).(R).(O).(Z).INFO , cINFO_I ] = compareINFOS( INFO_Z , cINFO_I );
            D.(P).(T).(R).(O).(Z).INFO = add_z_atts( D.(P).(T).(R).(O).(Z).INFO , D.(P).(T).(R).(O).(Z) );
            F = fieldnames( cINFO_I );
            for i = 1:numel(IS),   I= IS{i}; D.(P).(T).(R).(O).(Z).(I).INFO = rmfield( D.(P).(T).(R).(O).(Z).(I).INFO , F ); end
            
          end
          
          for z = 1:numel(ZS),   Z= ZS{z}; cINFO_Z = remove_unequals( cINFO_Z , D.(P).(T).(R).(O).(Z).INFO ); end
          [ D.(P).(T).(R).(O).INFO , cINFO_Z ] = compareINFOS( INFO_O , cINFO_Z );
          D.(P).(T).(R).(O).INFO = add_z_atts( D.(P).(T).(R).(O).INFO , D.(P).(T).(R).(O) );
          F = fieldnames( cINFO_Z );
          for z = 1:numel(ZS),   Z= ZS{z}; D.(P).(T).(R).(O).(Z).INFO = rmfield( D.(P).(T).(R).(O).(Z).INFO , F ); end

        end

        for o = 1:numel(OS),   O= OS{o}; cINFO_O = remove_unequals( cINFO_O , D.(P).(T).(R).(O).INFO ); end
        [ D.(P).(T).(R).INFO , cINFO_O ] = compareINFOS( INFO_R , cINFO_O );
        D.(P).(T).(R).INFO = add_z_atts( D.(P).(T).(R).INFO , D.(P).(T).(R) );
        F = fieldnames( cINFO_O );
        for o = 1:numel(OS),   O= OS{o}; D.(P).(T).(R).(O).INFO = rmfield( D.(P).(T).(R).(O).INFO , F ); end
        
      end

      for r = 1:numel(RS),   R= RS{r}; cINFO_R = remove_unequals( cINFO_R , D.(P).(T).(R).INFO ); end
      [ D.(P).(T).INFO , cINFO_R ] = compareINFOS( INFO_T , cINFO_R );
      D.(P).(T).INFO = add_z_atts( D.(P).(T).INFO , D.(P).(T) );
      F = fieldnames( cINFO_R );
      for r = 1:numel(RS),   R= RS{r}; D.(P).(T).(R).INFO = rmfield( D.(P).(T).(R).INFO , F ); end
      
    end
    
    for t = 1:numel(TS),   T= TS{t}; cINFO_T = remove_unequals( cINFO_T , D.(P).(T).INFO ); end
    [ D.(P).INFO , cINFO_T ] = compareINFOS( INFO_P , cINFO_T );
    D.(P).INFO = add_z_atts( D.(P).INFO , D.(P) );
    F = fieldnames( cINFO_T );
    for t = 1:numel(TS),   T= TS{t}; D.(P).(T).INFO = rmfield( D.(P).(T).INFO , F ); end
    
  end
    
  for p = 1:numel(PS),   P= PS{p}; cINFO_P = remove_unequals( cINFO_P , D.(P).INFO ); end
  [ D.INFO , cINFO_P ] = compareINFOS( INFO_ , cINFO_P );
  D.INFO = add_z_atts( D.INFO , D );
  F = fieldnames( cINFO_P );
  for p = 1:numel(PS),   P= PS{p}; D.(P).INFO = rmfield( D.(P).INFO , F ); end

  
  function names = getFieldNames( S , str )
    names = fieldnames(S);
    names = names( strncmp( names , str , numel(str) ) );
  end

  function A = add_z_atts( A , B )
    %D.(P).(T).(R).(O).(Z).INFO = add_z_atts( D.(P).(T).(R).(O).(Z).INFO , D.(P).(T).(R).(O).(Z) );
    F = fieldnames(B); F = sort( F( strncmp(F,'z',1) ) );
    for f = 1:numel(F)
      if isfield( A , F{f} ), continue; end
      A.(F{f}) = B.(F{f});
    end
  end

  function A = remove_unequals( A , B )
    if isempty(A)
      A = B;
      F = fieldnames(A); F = F( strncmp(F,'z',1) );
      A = rmfield( A , F );
    else
      F = fieldnames(A);
      for f = 1:numel(F)
        if  isfield( B , F{f} ) &&...
            isequal( A.(F{f}) , B.(F{f}) )
          F{f} = '';
        end
      end
      F( cellfun('isempty',F) ) = [];
      A = rmfield( A , F );
    end
  end


  function [ A , B ] = compareINFOS( A , B )
    %[ INFO_Z , cINFO_inI ] = compareINFOS( INFO_Z , cINFO_inI );
    if ~isstruct( B ), B = struct(); end
    if isempty( A )
      A = B;
    else
      F = fieldnames(B);
      for f = 1:numel(F)
        if ~isfield( A , F{f} )
          A.(F{f}) = B.(F{f});
        elseif ~isequal( A.(F{f}) , B.(F{f}) )
          B = rmfield( B , F{f} );
        end
      end
    end
  end
    


end
