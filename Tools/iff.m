function x = iff( pred , si , no )
  if nargin < 3, no = false; end

  if numel(pred) == 1

    if pred
      x = si;
    else
      x = no;
    end
    
  else
    
    x = si;
    x( ~pred ) = no( ~pred );
    
  end
  

end
