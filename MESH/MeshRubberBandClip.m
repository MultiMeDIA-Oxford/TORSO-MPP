function [M,plane] = MeshRubberBandClip( M , p )

  normal = @(t,p)[ sin(t) * cos(p) , sin(t) * sin(p) , cos(t) ];
  
  n = [0 0];
  n = ExhaustiveSearch( @(n)BandLength( normal(n(1),n(2)) ) , n , 0.1 , 5 );
  n = Optimize( @(n)BandLength( normal(n(1),n(2)) ) , n , 'methods' , {'conjugate','coordinate',2} , 'ls' , {'quadratic','golden','quadratic'} , 'noplot','verbose',0 , struct('COMPUTE_NUMERICAL_JACOBIAN',{{'f'}}) );
  n = normal( n(1) , n(2) );
  
  
  function L = BandLength( n )
    try
      
      C = meshSlice( M , [ p ; n(:).' ] , 'cell' );
      
      for c = 1:numel(C)
        C{c} = sum( sqrt( sum( diff( C{c} ,1,1).^2 ,2) ) );
      end
      
      L = max( [ C{:} ] );
    
    catch
      L = 1e8;
    end    
    
  end
  
  plane = [ p ; n(:).' ];
  plane = getPlane( plane );

  M = MeshClip( M , plane , 2 );

end
