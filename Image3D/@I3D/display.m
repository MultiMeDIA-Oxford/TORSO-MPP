function display(I)

  varname = inputname(1);
  if ~isempty( varname )  && ~strcmp( varname ,'ans' )
    fprintf( '%s :\n', varname );
  end

  sz= size(I);
  fprintf('         Image Size : %d(i) x %d(j) x %d(k) x %d(t)' , sz(1),sz(2),sz(3),sz(4) );

  if iscell( I.data )
    
    fprintf('\n\n' );
    C = I.data;
    for c = 1:numel(C)
      switch class( C{c} )
        case 'char'
          fprintf( '     #read        ''%s''\n' , C{c} );
        case 'function_handle'
          fprintf( '     #apply       %s\n' , func2str( C{c} ) );
        case 'cell'
          fprintf( '     #apply       %s\n' , C{c}{1} );
      end
    end
    fprintf('\n' );
    
  else

    fprintf('   <' );
    
    if ~isempty(I.data) && ( numel(I.X) ~= size(I.data,1)  ||  numel(I.Y) ~= size(I.data,2)  ||  numel(I.Z) ~= size(I.data,3)  ||  numel(I.T) ~= size(I.data,4) )
        warning('I3D:InvalidSize','Size I.data do not coincide with I.X , I.Y , I.Z , I.T');
    end  

    if numel( sz ) == 5
      if sz(5) == 0
        fprintf('empty');
      elseif sz(5)==1
        fprintf('scalar');
      else
        fprintf('%d components',sz(5));
      end
    else
      fprintf('(');
      for d= 5:numel(sz)
        fprintf('%dx',sz(d));
      end
      fprintf('\b) components');
    end
    %d(components)
    if ~I.isGPU
      fprintf(' x %s>\n' , class( I.data ) );
    else
      fprintf(' x GPU:%s>\n' , classUnderlying( I.data ) );
    end      

  end
  
  if I.isGPU
    fprintf('\n');
    fprintf('******  GPUvars  ***********\n');
    display( I.GPUvars );
    fprintf('****************************\n');
    fprintf('\n');
  end

  fprintf('                         ( %d ) x %d\n', numel(I.X)*numel(I.Y)*numel(I.Z) , numel(I.T) );
  
  
  
  fprintf('             X grid :     '); disp_grid( I.X );
  if ~issorted(I.X), warning('I3D:NotSortedCoordinates','X coordinates are not in increasing order.'); end    

  fprintf('             Y grid :     '); disp_grid( I.Y );
  if ~issorted(I.Y), warning('I3D:NotSortedCoordinates','Y coordinates are not in increasing order.'); end    

  fprintf('             Z grid :     '); disp_grid( I.Z );
  if ~issorted(I.Z), warning('I3D:NotSortedCoordinates','Z coordinates are not in increasing order.'); end    

  fprintf('              Times :     '); disp_grid( I.T );
  if ~issorted(I.T), warning('I3D:NotSortedCoordinates','T coordinates are not in increasing order.'); end    
%   fprintf('\n');


  vox_vol = voxelvolume( I );
%   fprintf('        Voxel volume: %.6g\n\n', vox_vol);
  
  if isempty( I.LABELS )
    fprintf('    EMPTY LABELS !!!!\n');
  else

    vols = accumarray( I.LABELS( ~~I.LABELS ) , 1 );
    
    L = false(1,65535);
    L( I.LABELS( ~~I.LABELS ) ) = true;
    L = find( L );
    for l = L(:)'
      if l == 0, continue; end
      state= ' ';
      if I.LABELS_INFO(l).state, state= '*';  end

      fprintf(' %sLabel %5d : %40s',state, l , I.LABELS_INFO(l).description );
      fprintf(' - volume: %8g ( %6d ) - alpha: %1.2f  - color: %1.01f %1.01f %1.01f', vols(l)*vox_vol , vols(l) , I.LABELS_INFO(l).alpha, I.LABELS_INFO(l).color );

%       [colorname,distance]= rgb2colorname( I.LABELS_INFO(l).color );
%       if distance == 0
%         fprintf('( %s )', colorname );
%       end
      fprintf('\n' );
    end
  end

  
  if ~isempty( I.LANDMARKS )
    fprintf('\n    LANDMARKS: ');
    
    if iscell( I.LANDMARKS )
      
    elseif isstruct( I.LANDMARKS )
      
    elseif isfloat( I.LANDMARKS )
      sz = size( I.LANDMARKS );
      fprintf( '( ' );
      for i = 1:numel(sz)-1
        fprintf( '%d x ' , sz(i) );
      end
      fprintf( '%d ) points' , sz(end) );
    else
      
    end
    fprintf('\n');
  end

  if ~isempty( fieldnames( I.CONTOURS ) )
    fprintf('\n    CONTOURS: \n');
    for f = fieldnames( I.CONTOURS ).'
      fprintf( '         %8d   points in %s\n', size( I.CONTOURS.(f{1}) , 1 ) , f{1} );
    end
    fprintf('\n');
  end
  
  
  if ~isempty( I.MESHES )
    nM = numel( I.MESHES );
    eM = nnz( cellfun('isempty',I.MESHES) );
    fprintf('\n');
    if nM == 1 && eM == 1
      fprintf('    there is 1 empty mesh.');
    elseif nM == 1
      fprintf('    there is 1 mesh.');
    elseif nM ~= 1 && nM == eM
      fprintf('    there are %d empties meshes.', nM );
    else
      fprintf('    there are %d meshes ( %d empties).', nM , eM );
    end
    fprintf('\n');
  end
  
  
  strans= dispcapture( I.SpatialTransform );
  fprintf('\n  Spatial Transform : | %s |     det: %g\n', strans{1} , det( I.SpatialTransform ) );
  fprintf('                      | %s |     svd: %g,%g,%g\n', strans{2} , ssvd( I.SpatialTransform(1:3,1:3) ) );
  fprintf('                      | %s |\n', strans{3:end} );
  if ~isequal( I.SpatialTransform(4,:) , [0 0 0 1] )
     warning('I3D:SpatialTransform','The SpatialTransform is not an homogeneous affine transform.');
  end  

  
%   [t_with_DFi,t_with_DFj] = ind2sub( size(I.DeformationField) ,  find( ~cellfun( @isempty , I.DeformationField  ) ) );
%   t_with_DF = [ t_with_DFi(:) , t_with_DFj(:) ]';
%   if ~isempty( t_with_DF )
%     fprintf('The IMAGE have     DeformationFields at times: ');
%     fprintf(' {%d,%d} ', t_with_DF );
%     fprintf('\n');
%   end
% 
%   [t_with_DFi,t_with_DFj] = ind2sub( size(I.invDeformationField) ,  find( ~cellfun( @isempty , I.invDeformationField  ) ) );
%   t_with_DF = [ t_with_DFi(:) , t_with_DFj(:) ]';
%   if ~isempty( t_with_DF )
%     fprintf('The IMAGE have  invDeformationFields at times: ');
%     fprintf(' {%d,%d} ', t_with_DF );
%     fprintf('\n');
%   end

  fprintf('Spatial Interpolation: %s ', I.SpatialInterpolation );
  fprintf(' - Boundary Mode: %s ', I.BoundaryMode );
  if strncmp( I.BoundaryMode , 'decay' , 5 )
    fprintf('( %g )', I.BoundarySize );
  end
  fprintf(' - Outside Value: %f\n', I.OutsideValue );

  fprintf('Spatial Stencil: %s ', I.DiscreteSpatialStencil );
  fprintf('   - Temporal Stencil: %s\n', I.DiscreteTemporalStencil );
  
  if ~isempty( I.INFO ) 
    fprintf('INFO : \n' );
    if numel( fieldnames( I.INFO ) ) > 10
      fprintf('      too many data in INFO. run I.INFO to display them.\n');
    else
      disp( I.INFO );
    end
  end
  if ~isempty( I.OTHERS ) 
    fprintf('OTHERS : \n' );
        disp( I.OTHERS );
  end
  if ~isempty( I.GRID_PROPERTIES ) 
    fprintf('GRID_PROPERTIES : \n' );
        disp( I.GRID_PROPERTIES );
  end
  if ~isempty( I.FIELDS )
    fprintf('FIELDS : \n' );
    for fn = fieldnames(I.FIELDS)'
      fprintf( '  %25s : ', fn{1} );

      if iscell( I.FIELDS.(fn{1}) ), 
        fprintf('packedfield\n');
        continue; 
      end
      
      fprintf('(');
      fprintf(' %3d', size( I.FIELDS.(fn{1}) ) );
      fprintf(' ) ');
      fprintf('%s\n', class( I.FIELDS.(fn{1}) ) );
      if isa( I.FIELDS.(fn{1}) , 'I3D' ), 
        continue; 
      end
      for k = 1:3
        if size( I.FIELDS.(fn{1}) , k ) ~= size( I.data , k )  && ~iscell( I.data )
          warning('I3D:IncorrectFieldSize','The Field ''%s'' have an invalid size.',fn{1});
          break;
        end
      end
    end
  end
  




  function disp_grid( X )
    if numel(X) > 4
      D1= mean( diff(X) );
      if all( abs( diff(X) - D1 ) < 1e-4 )
        fprintf( '%g : %g : %g' , X(1),D1,X(end) );
      else
        fprintf( '%g ', X );
      end
      fprintf( '\n' );
    else
      fprintf( '%g ', X );
      fprintf( '\n' );
    end
  end

end
