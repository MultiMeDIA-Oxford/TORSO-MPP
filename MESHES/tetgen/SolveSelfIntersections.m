function M = SolveSelfIntersections( M , varargin )

  [ DIR , CLEANUP ] = tmpname( 'tetgen_self_intersect_????\' , 'mkdir' );
  Sname = fullfile( DIR , 'M.smesh' );

  METHOD = [];
  [varargin,METHOD] = parseargs(varargin , 'smooth' , '$FORCE$',{'smooth',METHOD} );
  [varargin,METHOD] = parseargs(varargin , 'remove' , '$FORCE$',{'remove',METHOD} );
  [varargin,METHOD] = parseargs(varargin , 'mark'   , '$FORCE$',{'mark'  ,METHOD} );
  if isempty( METHOD ),
    METHOD = 'smooth';
  end
  
  switch METHOD
    case 'smooth'
  
      it = 0;
      M0 = M.xyz;
      while CheckSelfIntersections( M , Sname )
        it = it + 1;
        fprintf('it: %d\n',it);
        M = vtkSmoothPolyDataFilter( M , 'SetNumberOfIterations' , 1 , varargin{:} );
        M.xyz = transform( M.xyz , MatchPoints( M0 , M.xyz , 'Gt' ) );
        if it > 200, break; end
      end
      
    case 'remove'
      
      M = Mesh( M ,0);
      while 1
        [issi,SIfaces] = CheckSelfIntersections( M );
        if ~issi, break; end
        while 1
          [e,~,d] = vtkClosestElement( M , double( meshFacesCenter( SIfaces ) ) );
          w = d < 1e-8;
          if ~any(w), break; end
          M.tri( e(w) , : ) = [];
        end
      end
      
    case 'mark'
      
      M = Mesh( M );
      M.triSIF = zeros( size( M.tri ,1) ,1);
%       while 1
        [issi,SIfaces] = CheckSelfIntersections( M );
        if ~issi, return; end

        [e,~,d] = vtkClosestElement( M , FacesCenter( SIfaces ) );
        M.triSIF(e) = 1;
%       end
      
    otherwise
      error('unknown method');
  end

end
