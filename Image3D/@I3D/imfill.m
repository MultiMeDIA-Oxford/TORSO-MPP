function [I,locations] = imfill( I , varargin )
% 


  if  isempty( I.data ), error('the image have to be a non empty image'); end
  if ~isbinary( I )
    error('the image have to be a binary image');
  end
  I = remove_dereference( I );


  [I.data,locations] = imfill( I.data , varargin{:} );
  
end
