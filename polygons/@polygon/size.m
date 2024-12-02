function [a,b]=size(C,d)


if (nargout<2)
    if nargin<2, a=size(C.XY);
    else a=size(C.XY,d);
    end;
elseif (nargout==2)&&(nargin==1)
    [a,b]=size(C.XY);
else error('Too many output arguments.');
end;

