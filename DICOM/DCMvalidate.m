function D = DCMvalidate( D , removeInvalidOrientations )
%
% if substruct is given, complete the previous needed fields.
% also, check if the orientations are valid volumes (structured)
% if some orientation is not a valid volume, it is removed or renamed to
% 'Orientation_dd_'.
%

  if nargin < 2, removeInvalidOrientations = false; end

  PS = getFieldNames( D , 'Patient_' ); if isempty(PS),PS={'Patient_00'};D=struct(PS{1},D);end
  for p = 1:numel(PS),  P= PS{p};
    
    TS = getFieldNames( D.(P) , 'Study_' ); if isempty(TS),TS={'Study_00'};D.(P)=struct(TS{1},D.(P));end
    for t = 1:numel(TS),   T= TS{t};

      RS = getFieldNames( D.(P).(T) , 'Serie_' ); if isempty(RS),RS={'Serie_00'};D.(P).(T)=struct(RS{1},D.(P).(T));end
      for r = 1:numel(RS),   R= RS{r};

        OS = getFieldNames( D.(P).(T).(R) , 'Orientation_' ); if isempty(OS),OS={'Orientation_00'};D.(P).(T).(R)=struct(OS{1},D.(P).(T).(R));end
        for o = 1:numel(OS),   O= OS{o};
        
          ZS = getFieldNames( D.(P).(T).(R).(O) , 'Position_' ); if isempty(ZS),ZS={'Position_000'};D.(P).(T).(R).(O)=struct(ZS{1},D.(P).(T).(R).(O));end
          for z = 1:numel(ZS),   Z= ZS{z};

            IS = getFieldNames( D.(P).(T).(R).(O).(Z) , 'IMAGE_' ); if isempty(IS),IS={'IMAGE_000'};D.(P).(T).(R).(O).(Z) = struct( IS{1} , D.(P).(T).(R).(O).(Z) );end
%             for i = 1:numel(IS),   I = IS{i};
%             end
            
          end
          
          nImages = NaN( numel(ZS) , 1 );
          for z = 1:numel(ZS),    Z= ZS{z};
            nImages(z) = numel( getFieldNames( D.(P).(T).(R).(O).(Z) , 'IMAGE_' ) );
          end

          if any( nImages ~= nImages(1) )
            if removeInvalidOrientations
              %fprintf('delete: %s.%s.%s.%s\n',P,T,R,O);
              D.(P).(T).(R) = rmfield( D.(P).(T).(R) , O );
%             else
%               nO = regexprep( O , '^([^_]*)_(\d*).*' , '$1_$2_' );
%               %fprintf('rename: %s.%s.%s.%s   ->  %s\n',P,T,R,O,nO);
%               D.(P).(T).(R) = renameField(  D.(P).(T).(R) , O , nO );
            end
%           else
%             nO = regexprep( O , '^([^_]*)_(\d*).*' , '$1_$2' );
%             %fprintf('rename: %s.%s.%s.%s   ->  %s\n',P,T,R,O,nO);
%             D.(P).(T).(R) = renameField(  D.(P).(T).(R) , O , nO );
          end
          
        end
      end
    end
  end
     

  
  function names = getFieldNames( S , str )
    names = fieldnames(S);
    names = names( strncmp( names , str , numel(str) ) );
  end
  function S = renameField( S , oldName , newName )
    F = fieldnames(S);
    S = struct2cell(S);
    F{strcmp(F,oldName)} = newName;
    S = cell2struct(S,F);
  end
end
