function r = isidentical( X , Y )

  r = false;

  if ~isequal( class(X) , class(Y) ), return; end
  if ~isequal( numel(X) , numel(Y) ), return; end
  if ~isequal(  size(X) ,  size(Y) ), return; end


  if isa(X,'parallel.gpu.GPUArray')
    r = isidentical( gather(X) , gather(Y) );
    return;
  end
  
  
  if isnumeric(X)
    if isreal(X) ~= isreal(Y), return; end
    if ~isreal(X)
      r = isidentical( real(X) , real(Y) ) && isidentical( imag(X) , imag(Y) );
      return;
    end
  end
  
  if issparse( X ) && ~issparse( Y )
    return;
  end
  
  if issparse( X )
    if ~isequal( nonzeros(X) , nonzeros(Y) )
      return;
    end
    if ~isequal( nzmax(X) , nzmax(Y) )
      return;
    end
    r = isequal( X , Y );
    return;
  end
  
  
  if isnumeric( X )
    %r = builtin( 'isidentical',X,Y );

    try
      if numel(X) > 0
        r = isequal( typecast(X(1),'uint8') , typecast(Y(1),'uint8') );
        r = isequal( typecast( squeeze( X([1 end]) ),'uint8' ), typecast( squeeze( Y([1 end]) ),'uint8') );
      end
    catch
      keyboard
    end
    
    r = isequal( typecast( squeeze( X(1:end) ),'uint8') , typecast( squeeze( Y(1:end) ),'uint8') );
%     r = all( typecast(X(1:end),'uint8') == typecast(Y(1:end),'uint8') );
    return;
  end
  
  if islogical( X )  || ischar( X ) 
    r = isequal( X(:) , Y(:) );
    return;
  end


  if iscell( X )
    for i = 1:numel(X)
      if ~isidentical( X{i} , Y{i} )
        return;
      end
    end
  end
  
  if isstruct( X )
    FNx = fieldnames( X );
    if ~isidentical( FNx , fieldnames( Y ) )
      return;
    end

    for i = 1:numel(X)
      for f = FNx(:).'
        if ~isidentical( X(i).(f{1}) , Y(i).(f{1}) )
          return;
        end
      end
    end
  end

  if isa( X , 'function_handle' )
%     for v = [ -10 -1 -0.1 0 0.1 1 10 ]
%       if ~isidentical( X(v) , Y(v) )
%         return;
%       end
%     end
  end
  
  r = true;

end
