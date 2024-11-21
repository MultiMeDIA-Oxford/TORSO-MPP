function D = DCMcopyfiles( D , dirname , varargin )
%
% 
% DCMcopyfiles( D0 , pwd , 'target',@(d,P,T,R,O,Z,I,info)...
% fullfile( d ,...
%   sprintf('%03d.%s_(%+0.3g)',info.SeriesNumber,info.SeriesDescription,info.xZLevel) ,...
%   iff( strcmp( O , 'Orientation_' ) ,...
%     '' ,...
%     strrep( O , 'Orientation_' , 'O' ) ) ,...
%     [ strrep( I , 'IMAGE_' , 'I' ) , '.dcm' ] ...
%     ) , 'move' )
% 
% 

  OVERRIDE = false;
  
  [varargin,VERBOSE] = parseargs(varargin,'verbose','$FORCE$',{true,false});
  if VERBOSE
    vprintf  = @(varargin)fprintf(varargin{:});
    vdisp    = @(varargin)fprintf(varargin{:});
  else
    vprintf  = @(varargin)[];
    vdisp    = @(varargin)[];
  end

  ACTION = 'COPY';
  [varargin,ACTION] = parseargs(varargin,'copy' ,'$FORCE$', { 'COPY' , ACTION } );
  [varargin,ACTION] = parseargs(varargin,'move' ,'$FORCE$', { 'MOVE' , ACTION } );
  [varargin,ACTION] = parseargs(varargin,'test' ,'$FORCE$', { 'TEST' , ACTION } );
  [varargin,ACTION] = parseargs(varargin,'test1','$FORCE$', { 'TEST1' , ACTION } );


  TARGET = @(dirname,P,T,R,O,Z,I,info) fullfile( dirname , P , T , R , O , [ strrep( Z , '_' , '' ) , '_' , strrep( I , '_' , '' ) ] );
  [varargin,~,TARGET] = parseargs(varargin,'TARGETfilename','$DEFS$', TARGET );
  if ischar( TARGET )
    if 0
    elseif strcmpi( TARGET , 'compact' )
      TARGET = @(dirname,P,T,R,O,Z,I,info)COMPACT(dirname,P,T,R,O,Z,I,info);
    end
  end
  
  
  D = DCMvalidate( D );

  PS= getFieldNames( D , 'Patient_' );
  for p = 1:numel(PS),  P = PS{p};
    TS = getFieldNames( D.(P) , 'Study_' );
    for t = 1:numel(TS),   T = TS{t};
      RS = getFieldNames( D.(P).(T) , 'Serie_' );
      for r = 1:numel(RS),   R = RS{r};
        OS = getFieldNames( D.(P).(T).(R) , 'Orientation_' );
        for o = 1:numel(OS),   O = OS{o};
          ZS = getFieldNames( D.(P).(T).(R).(O) , 'Position_' );
          for z = 1:numel(ZS),   Z = ZS{z};
            IS = getFieldNames( D.(P).(T).(R).(O).(Z) , 'IMAGE_' );
            for i = 1:numel(IS),   I = IS{i};
              
              source = fullfile( D.(P).(T).(R).(O).(Z).(I).zDirname , D.(P).(T).(R).(O).(Z).(I).zFilename );
              %source = strrep( source , 'c:\' , 'e:\' );
              
              try
                target = TARGET( dirname , P , T , R , O , Z , I , D.(P).(T).(R).(O).(Z).(I).info );
              catch
                try
                  fprintf('error in file: ''%s''\n',D.(P).(T).(R).(O).(Z).(I).zFileName);
                catch
                  keyboard;
                end
                continue;
              end
              
              [dirtarget,fntarget,extarget] = fileparts( target );

              if isequal( source , target )
                vprintf('SOURCE NAME equals TARGET NAME\n');
                continue;
              end
              if isfile( target , 'fast' )
                fprintf('TARGET file already exists. ("%s" --> "%s")', source , target );
                if areDuplicates( source , target )
                  vprintf('.. and are DUPLICATED!\n');
                  continue;
                end
                vprintf('\n');
                
                if ~OVERRIDE, continue; end
              end
              
              switch ACTION
                case 'COPY'
                  if ~isdir( dirtarget ), mkdir( dirtarget ); end
                  vdisp('copying "%s"  to  "%s"\n',source , target );
                  copyfile( source , target );
                case 'MOVE'
                  if ~isdir( dirtarget ), mkdir( dirtarget ); end
                  vdisp('moving "%s"  to  "%s"\n',source , target );
                  movefile( source , target );
                case 'TEST' , fprintf('"%s"  -->  "%s"\n',source , target ); continue;
                case 'TEST1', fprintf('"%s"  -->  "%s"\n',source , target ); return;
                otherwise, error('incorrect COPY or MOVE');
              end              
              
              
              D.(P).(T).(R).(O).(Z).(I).info.Filename   = target;
              D.(P).(T).(R).(O).(Z).(I).zFileName       = target;
              D.(P).(T).(R).(O).(Z).(I).INFO.zFileName  = target;
              D.(P).(T).(R).(O).(Z).(I).INFO.zDirname   = dirtarget;
              D.(P).(T).(R).(O).(Z).(I).INFO.zFilename  = [ fntarget , extarget ];
              D.(P).(T).(R).(O).(Z).(I).zDirname        = dirtarget;
              D.(P).(T).(R).(O).(Z).(I).zFilename       = [ fntarget , extarget ];
              
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
end
function fn = COMPACT( dn ,P,T,R,O,Z,I,info)

  try

    zl = info.xZLevel;
    zl = sprintf( '%+.15f', zl );
    zl = [ zl(1) , '000' , zl(2:end) , '000' ];
    id = find(zl=='.');
    zl = zl( [ 1 , id-3:id+2 ] );
    zl = [ '_(@z' , zl , ')' ];
    
  catch
    
    zl = '';
    
  end

  fn = {};
  fn{end+1} = dn;
  fn{end+1} = sprintf('%03d.%s',info.SeriesNumber,info.SeriesDescription);
  
  if strcmp( O , 'Orientation_' ) && strcmp( Z , 'Position_' )
    fn{end} = [ fn{end} , zl ];
  end
  if ~strcmp( O , 'Orientation_' )
    fn{end+1} = strrep( O , 'Orientation_' , 'O' );
  end
  if ~strcmp( Z , 'Position_' )
    fn{end+1} = [ strrep( Z , 'Position_' , 'Z' ) , zl ];
  end
  if strcmp( I , 'IMAGE_' ) && ~strcmp( Z , 'Position_' )
    fn{end}   = [];
    fn{end+1} = [ 'I' , zl , '.dcm' ];
  else
    fn{end+1} = [ strrep( I , 'IMAGE_' , 'I' ) , '.dcm' ];
  end
  
  fn = fullfile( fn{:} );
    
end


