function I = repmat( I , sz )

  prev_dereference = I.POINTER;

  for d=1:numel(sz)
    if d <= 4
      II=I;
      for t = 1:sz(d)-1
        I= cat(d,I,II);
      end
    else
      I.data = repmat( I.data , [ ones(1,d-1) , sz(d) ] );
    end
  end

  
  if ~isempty( I.FIELDS )
    for fn = fieldnames(I.FIELDS)'
      if isa( I.FIELDS.(fn{1}) , 'I3D' ), continue; end
      I.FIELDS.(fn{1}) = repmat( I.FIELDS.(fn{1}) , sz );
    end
  end  
  
  
  I.POINTER = prev_dereference;

  I = DATA_action( I , [ '@(X) repmat(X,' uneval(sz)  ')' ], 0 );

end
