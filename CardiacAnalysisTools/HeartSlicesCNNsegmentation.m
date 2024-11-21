function [C,CC,M] = HeartSlicesCNNsegmentation( I , vn )

  persistent lastI
  if isempty( lastI ), lastI = {[],[]}; end

  if iscell( I )
    for r = 1:size(I,1)
      vn = [];
      if isa( I{r,1} , 'I3D' ) && isfield( I{r,1}.INFO , 'PlaneName' )
        vn = I{r,1}.INFO.PlaneName;
        if isempty( vn ), vn = '?'; end
      else
        try
          vn = slicePlaneName( I{r,1} );
        end
      end
      if any( strcmpi( vn , {'ax','cor','?'} ) ), continue; end

      fprintf( 'Segmenting slice %2d of %d:  "%s" ... ' , r , size( I ,1) , vn );
      C = HeartSlicesCNNsegmentation( I{r,1}.t1 , vn );
      fprintf( 'done.\n' );
      I(r,2:4) = C;
    end
    C = I;
    
    if nargout > 1
      CC = C;
      
      SA1 = FirstSA( I );
      
      fprintf( 'Fixing EPI ... ' );
      M{1,1} = Contours2Surface_ez( C([1,2,3,SA1+3:end-3],2) ,'STIFFNESS',2000,'FARTHESTP_RESAMPLING',10,'SMTHDEC_ITER',25,'MAX_DEFORMATION_ITS',100,'FARTERPOINTS', -3 ,'TARGETREDUCTION',0.715 ,'blid',25,'ulid',25);
      CC(:,2) = arrayfun( @(r)meshSlice(M{1,1},C{r,1}) , 1:size(C,1) , 'un',0);
      fprintf( 'done.\n' );
      
      
      fprintf( 'Fixing LV  ... ' );
      M{1,2} = Contours2Surface_ez( C([1,2,3,SA1+3:end-3],3) ,'STIFFNESS',2000,'FARTHESTP_RESAMPLING',10,'SMTHDEC_ITER',25,'MAX_DEFORMATION_ITS',100,'FARTERPOINTS', -3 ,'TARGETREDUCTION',0.715 ,'blid',25,'ulid',25);
      CC(:,3) = arrayfun( @(r)meshSlice(M{1,2},C{r,1}) , 1:size(C,1) , 'un',0);
      fprintf( 'done.\n' );

      
      fprintf( 'Fixing RV  ... ' );
      M{1,3} = Contours2Surface_ez( C([1,2,3,SA1+3:end-3],4) ,'STIFFNESS',2000,'FARTHESTP_RESAMPLING',10,'SMTHDEC_ITER',25,'MAX_DEFORMATION_ITS',100,'FARTERPOINTS', -3 ,'TARGETREDUCTION',0.715 ,'blid',25,'ulid',25);
      CC(:,4) = arrayfun( @(r)meshSlice(M{1,3},C{r,1}) , 1:size(C,1) , 'un',0);
      fprintf( 'done.\n' );
    end

    return;
  end


  switch getHOSTNAME
    case 'ENGS-24337'
      PYTHONexe = 'set PATH=%PATH%;"C:\Program Files\Anaconda3";"C:\Program Files\Anaconda3\Scripts";"C:\Program Files\Anaconda3\Library\bin" & "C:\Program Files\Anaconda3\python"  '; 
      CNNdir    = 'E:\Dropbox\Vigente\Segmentation2D\';
    otherwise
      PYTHONexe = 'set PATH=%PATH%;"C:\Anaconda3\";"C:\Anaconda3\Scripts\";"C:\Anaconda3\Library\bin\";"C:\Anaconda3\envs\tensorflow\";"C:\Anaconda3\Lib\site-packages\numpy\core\"  & "C:\Anaconda3\python"  ';
      CNNdir    = 'C:\CMR analysis\Segmentation2D\';
  end              




  if ~isa(I,'I3D'), error('an I3D was expected'); end
  if size( I ,3) ~= 1, error('only for slices.'); end
  if size( I ,4) ~= 1, error('only for single phases.'); end
  if size( I ,5) ~= 1, error('only for scalar images.'); end
  if prod( size(I,3:max(6,ndims(I.data))) ) ~= 1
    error('multidimensional images not allowed');
  end

  if nargin < 2, vn = []; end
  if isempty( vn ), vn = slicePlaneName( I ); end
  
  %%

  I0 = [];
%   I0 = I;
  I = I.matrix2coords;
  
  try
    I = crop( I , 0 , 'Mask' , expand( I.FIELDS.Hmask , size(I) ) );
  end
  
  W = min( ( I.X(end) - I.X(1) ) , ( I.Y(end) - I.Y(1) ) );
  x = linspace( -1/2 , 1/2 ,128 )*W;
  y = x;
  x = x + mean( I.X([1 end]) );
  y = y + mean( I.Y([1 end]) );

  I = resample( I , { x , y , I.Z } );
  I = todouble( I );
  
  prc = 0;
  
  I = I - prctile( I ,     prc );
  I = I / prctile( I , 100-prc );
  I = clamp( I , 0 , 1 );
  
  
  if isequal( lastI{1,1} , I.data )
    
    seg = lastI{1,2};
    
  else
  
    [input ,CLEANi] = tmpname( 'input_haoCNN*****.png' , 'mkfile' );
    [output,CLEANo] = tmpname( 'output_haoCNN*****.png' , 'mkfile' );
    imwrite( I.data.' , input );

    switch lower( vn )
      case {'hlax','vlax','hla','vla','la','lax','lvot'}
        vn = 'LAX';
      case {'sax','sa'}
        vn = 'SAX';
    end

    cmd = sprintf( '"%s"  "%s"  "%s"  "%s"  %s' ,...
      fullfile(CNNdir,'Segmentation2D.py') ,...
      input , output , CNNdir , vn );

    [result,stdout] = system( sprintf('%s %s',PYTHONexe,strrep(cmd,filesep,'/') ));
    if result > 0
      keyboard;
    end

    seg = imread( output );
    
    lastI{1,1} = I.data;
    lastI{1,2} = seg;
    
  end

  C{1,1} = contourc( I.fill( seg(:,:,2).' ) , [100 100] );
  C{1,2} = contourc( I.fill( seg(:,:,1).' ) , [100 100] );
  C{1,3} = contourc( I.fill( seg(:,:,3).' ) , [100 100] );

  for c = 1:3
    if isempty( C{c} ), C{c} = []; continue; end
    C{c} = polyline( C{c} );
    C{c} = double( C{c}( argmax( C{c}.nn ) ) );
  end

  if ~isempty( I0 )
    image3( I0 );
    hplot3d( C{1} , 'r' );
    hplot3d( C{2} , 'g' );
    hplot3d( C{3} , 'b' );
  end
  
  %%
end
