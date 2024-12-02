function [vi h v]= viewfrom( aa )

  if nargin<1, aa = gca; end
  h= '';  v= '';

  vi= get(aa,'view');
  if      vi(2)== 90
    vi= '+Z';
  elseif  vi(2)== -90
    vi= '-Z';
  elseif  vi(2)==0 && vi(1)== 0
    vi= '-Y';
  elseif  vi(2)==0 && vi(1)== 90
    vi= '+X';
  elseif  vi(2)==0 && (vi(1)== 180 || vi(1)== -180)
      vi= '+Y';
  elseif  vi(2)==0 && (vi(1)== -90 || vi(1)== 270 )
      vi= '-X';
  end
  
  if ischar(vi)
    up= get(aa,'CameraUpVector');
    if      all( up == [ 0  0  1] ),    up= '(+Z)'; v='Z'; if vi(2)=='X', h='Y'; end; if vi(2)=='Y', h='X'; end;
    elseif  all( up == [ 0  0 -1] ),    up= '(-Z)'; v='Z'; if vi(2)=='X', h='Y'; end; if vi(2)=='Y', h='X'; end;
    elseif  all( up == [ 0  1  0] ),    up= '(+Y)'; v='Y'; if vi(2)=='X', h='Z'; end; if vi(2)=='Z', h='X'; end;
    elseif  all( up == [ 0 -1  0] ),    up= '(-Y)'; v='Y'; if vi(2)=='X', h='Z'; end; if vi(2)=='Z', h='X'; end;
    elseif  all( up == [ 1  0  0] ),    up= '(+X)'; v='X'; if vi(2)=='Y', h='Z'; end; if vi(2)=='Z', h='Y'; end;
    elseif  all( up == [-1  0  0] ),    up= '(-X)'; v='X'; if vi(2)=='Y', h='Z'; end; if vi(2)=='Z', h='Y'; end;
    else    up= '';
    end
    vi= [vi up];
  end
end
