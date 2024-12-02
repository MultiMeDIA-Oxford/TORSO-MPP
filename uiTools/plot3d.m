function [varargout] = plot3d( X , varargin )
%  plot3d   Plot of curves (2D or 3D)
%     plot3d( C ) plots the collection of points from the array C. C should
%     be an Nx2 (for 2d curves) or an Nx3 (for 3d curves) array where in
%     each row it is stored the coordinates of each spatial point.
% 
%     plot3d( C , linespec ) where linespec have the same conventions than
%     the ones used in the Matlab function plot.
% 
%     plot3d( C , [linespec] , varargin ) additional options can be
%     specified for the curve, such as,
%     'LineWidth','Color','Tag','DisplayName', etc (see line and its
%     properties for more information).
% 
%     This functionality is just an alias or short cut of:
%       plot3d( X ,... ) == plot3( X(:,1) , X(:,2) , X(:,3) ,...)
%             when C is a 3 columns matrix
%     and
%       plot3d( X ,... ) == plo( X(:,1) , X(:,2) ,...)
%             when C is a 2 columns matrix
% 
%     plot3d( { C } ,... ) (when the first argument is a cell) plot all the
%     set of curves within the cell. It is done by joining the element of C
%     by interleaving NaNs in between them such that the plot looks like
%     splitted curves.
% 
%     plot3d( A , B ,...) where A and B are arrays of equal size. It
%     connects each point specified in A with the corresponding specified
%     in B.
% 

  EQ = false;
  try, [varargin,EQ] = parseargs(varargin,'EQual','EQualAxis','AxisEQual','$FORCE$',{true,EQ}); end
  
  START = false;
  try, [varargin,START] = parseargs(varargin,'start','$FORCE$',{true,START}); end

  
  if isempty(X)
    [varargout{1:nargout}] = deal([]);
    return;
  end

  if iscell( X )
    X( cellfun( 'isempty' , X ) ) = [];
    Y = [];
    for x = 1:numel(X)
      if isempty( X{x} ), continue; end
      Y = [ Y ; X{x} ];
      Y(end+1,:) = NaN;
    end
    X = Y;
  end
  
  if isempty(X), return; end
  
    
  
  nsd = size( X , 2 );
  if numel( varargin ) && ~ischar( varargin{1} )
    Y = varargin{1};
    varargin(1) = [];

    try
      X = reshape( permute( cat(3,X,Y,nan(size(X))) , [3 1 2] ) , numel(X)*3/nsd , nsd );
    catch
      error('X and Y cannot be connected');
    end
  end

  varargin = getLinespec( varargin );
  
  if all( abs( X(:,3:end) ) < 1e-10 )
    X(:,3:end) = [];
    nsd = size(X,2);
  end
  
  if nsd == 3
    [varargout{1:nargout}] =  plot3( X(:,1) , X(:,2) , X(:,3) , varargin{:} );
    if START
      try, varargin = getLinespec( varargin ); end      
           line( X(1,1) , X(1,2) , X(1,3) , varargin{:} , 'Marker' ,'h','MarkerFaceColor','r'    ,'MarkerSize',15);
      try, line( X(2,1) , X(2,2) , X(2,3) , varargin{:} , 'Marker' ,'h','MarkerFaceColor','none' ,'MarkerSize',15); end
    end
  elseif nsd == 2
    [varargout{1:nargout}] =  plot( X(:,1) , X(:,2) , varargin{:} );
    if START
      try, varargin = getLinespec( varargin ); end      
           line( X(1,1) , X(1,2) , varargin{:} , 'Marker' ,'h','MarkerFaceColor','r'    ,'MarkerSize',15);
      try, line( X(2,1) , X(2,2) , varargin{:} , 'Marker' ,'h','MarkerFaceColor','none' ,'MarkerSize',15); end
    end
  elseif nsd == 1
    [varargout{1:nargout}] =  plot( X(:,1) , varargin{:} );
  else
    error('1, 2 or 3 columns were expected.');
  end
  
  if EQ
    set(gca,'DataAspectRatio',[1 1 1]);
  end
  
  
  
end
