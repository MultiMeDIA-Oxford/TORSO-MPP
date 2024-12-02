function [Ss1,Ss2] = notequalfields( S1 , S2 )

  PUT_NOEXISTE = false;

  if ~( isstruct( S1 ) && isstruct( S2 ) )
    Ss1= S1;
    Ss2= S2;
    return;
  end

  Ss1= struct();
  Ss2= struct();
  
  fields = unique( [ fieldnames( S1 ); fieldnames( S2 ) ] );
  while ~isempty( fields )
    f = fields{1};
    fields(1)= [];
    try
      if isidentical( S1.(f) , S2.(f) )
        continue;
      end
    end
    if       isfield( S1 , f )  &&  isfield( S2 , f )
      [a,b]= notequalfields( S1.(f) , S2.(f) );
      Ss1.(f)= a;
      Ss2.(f)= b;
    elseif  PUT_NOEXISTE && ~isfield( S1 , f )  &&  isfield( S2 , f )
      Ss1.(f) = no_existe( S2.(f) );
      Ss2.(f) = S2.(f);
    elseif  PUT_NOEXISTE &&  isfield( S1 , f )  && ~isfield( S2 , f )
      Ss2.(f) = no_existe( S1.(f) );
      Ss1.(f) = S1.(f);
    else
      try
        Ss1.(f)= S1.(f);
      catch
        if PUT_NOEXISTE
          Ss1.(f)= '---no_existe---';
        end
      end
      try
        Ss2.(f)= S2.(f);
      catch
        if PUT_NOEXISTE
          Ss2.(f)= '---no_existe---';
        end
      end
    end
  end

  if nargout < 2
    Ss1 = merge(Ss1,Ss2);
  end
  
  function S = merge(a,b)
    S = struct();
    fa= fieldnames( a );
    fb= fieldnames( b );
    for f=1:numel(fa)
      fn= fa{f};
      aa= a.(fn);
      if isfield(b,fn)
        bb= b.(fn);
        fb( strcmp(fb,fn) ) = [];
      else
        bb= '---no_existe---';
      end
      if isstruct( aa ) && isstruct( bb )
        S.(fn) = merge( aa , bb );
      else
        S.(fn) = { aa  bb };
      end
    end
  end


  function T = no_existe( T )
    
    if isstruct( T )
      fn = fieldnames( T );
      for i=1:numel(fn)
        T.(fn{i}) = no_existe( T.(fn{i}) );
      end
    else
      T = '---no_existe---';
    end
    
  end
  
  
end
