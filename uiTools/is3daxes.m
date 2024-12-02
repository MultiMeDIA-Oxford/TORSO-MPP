function is3d = is3daxes( aa )
  is3d = 1;
  proj= get(aa,'projection');
  if strcmp( proj, 'orthographic' )
    vi= viewfrom(aa);
    if ischar(vi)
      try
        if vi(4) == '+' || vi(4) == '-'
          is3d= 0;
        end
      end
    end
  end

end


