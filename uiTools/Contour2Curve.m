function C = Contour2Curve( X , Y , I )
%Contour2Curve zero-level-set computation and conversion to a curve.
% 
%   Contour2Curve converts the zero-level-set of an image to a 2D curve.
%
%   C = Contour2Curve( I ) computes the zero-level-set
%
%   C = Contour2Curve( x , y , I ), where x and y are vectors, specifies
%   the x- and y- grid of the image I.
%
%   C = Contour2Curve( X , Y , I ), where X and Y are the output of
%   ndgrid(x,y).
%
% 
%   Example:
%
%     load penny; P = P(1:100,:); imagesc( P.' );
%     hold on; plot3d( Contour2Curve( P - 100 ) , 'm' ); hold off;
% 
%   See also CONTOUR, CONTOURF, CONTOUR3.

  if      nargin == 1
    I = X;
    X = 1:size(I,1);
    Y = 1:size(I,2);
  elseif  nargin == 3
  else
    error('or 1 or 3 inputs were expected.');
  end

  if ~isvector(X), X = X(1:end,1).'; end
  if ~isvector(Y), Y = Y(1,1:end); end
  
  C = contourc( X , Y , double( I.' ) , [0 0]  );
  C = C.';
  
  i = 1;
  while i <= size(C,1)
    r = C(i,2);
    C(i,:) = NaN;
    i = i + r + 1;
  end
  C(1,:) = [];
  
end
