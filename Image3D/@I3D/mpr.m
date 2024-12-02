function M = mpr( I , pl , varargin )

  
  Ibb = transform( ndmat( I.X([1,end]) , I.Y([1,end]) , I.Z([1,end]) ) , I.SpatialTransform );

%   Ic = subsref( I , substruct('.','center'));
%   R = ipd( Ic , Ibb ); R = max( R(:) );

  [Ic,R] = miniball( Ibb );


  r = [ min( fro( diff( transform( ndmat( I.X(:) , I.Y(1) , I.Z(1) ) , I.SpatialTransform ) ,1,1) ,2) ) ;...
        min( fro( diff( transform( ndmat( I.X(1) , I.Y(:) , I.Z(1) ) , I.SpatialTransform ) ,1,1) ,2) ) ;...
        min( fro( diff( transform( ndmat( I.X(1) , I.Y(1) , I.Z(:) ) , I.SpatialTransform ) ,1,1) ,2) ) ];
  r = min(r);

  while 1
    try
      M = 0:r:(R+r); M = [ fliplr( -M ) , M(2:end) ];
      M = I3D([],'X',M,'Y',M,'Z',M);

      M = transform( M , pl );
      M = transform( M ,'t', Ic - subsref( M , substruct('.','center')) );

      M = subsref( I , substruct( '()' , {M ,'outside_value',NaN,'value',varargin{:}} ) );
      M = crop( M , 1 );
      break;
    end
    r = r * 1.5;
  end
  
  M = subsref( M , substruct('.','coords2matrix_noScale') );
  %M = nonans( M , 'euclidean' );
  
end

