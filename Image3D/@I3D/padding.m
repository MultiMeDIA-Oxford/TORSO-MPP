function I = padding( I , padsize , varargin )


  %%% parsing padsize and direction
  direction = 'both';
  [varargin,direction] = parseargs(varargin,'pre'  ,'$FORCE$',{'pre' ,direction});
  [varargin,direction] = parseargs(varargin,'post' ,'$FORCE$',{'post',direction});
  [varargin,direction] = parseargs(varargin,'both' ,'$FORCE$',{'both',direction});

  if iscell( padsize )
    c = repmat( padsize , [] , 2 );
    padsize = 0;
    for d = 1:size(c,1)
      s = c{d,2};
      if isscalar(s)
        switch direction
          case 'pre' ,  s = [ s ; 0 ];
          case 'post',  s = [ 0 ; s ];
          case 'both',  s = [ s ; s ];
        end
      end
      if numel(s) > 2, error('invalid padsize.'); end

      if ischar( c{d,1} ), c{d,1} = double( lower( c{d,1} ) - 'x' )+1; end
      padsize( 1:2 , c{d,1} ) = s(:);
    end
  end
  
  if size(padsize,1) == 1
    switch direction
      case 'pre' ,  padsize = [ padsize   ; padsize*0 ];
      case 'post',  padsize = [ padsize*0 ; padsize   ];
      case 'both',  padsize = [ padsize   ; padsize   ];
    end
  elseif size(padsize,1) > 2
    error('error in padsize');
  end
  
  if size( padsize , 2 ) == 1  &&  padsize(1) < 0
    padsize = repmat( -padsize , 1 , 3 );
  end

  if any( padsize(:) < 0 )
    error('invalid padsize. On negative -> all dims.');
  end
  padsize = padsize( : , 1:find( any(padsize,1) , 1 , 'last' ) );

  if size(padsize,2) > 3,
    error('I3D:invalidPadding','for I3D only allowed xyz (1,2,3) pads.');
  end

  padsize(1,4) = 0;
  padsize = padsize(:,1:3);
  %%%END parsing padsize and direction
  

  I.X = padding( I.X , { 2 , padsize(:,1) } , 'extend' );
  I.Y = padding( I.Y , { 2 , padsize(:,2) } , 'extend' );
  I.Z = padding( I.Z , { 2 , padsize(:,3) } , 'extend' );
    
  if ~isempty( I.data )
    I = DATA_action( I , [ '@(X) padding(X,' uneval( padsize , varargin{:} ) ')' ] );
  end

  if ~isempty( I.LABELS )
    I.LABELS = padding( I.LABELS , padsize , 'value', uint16(0) );
  end

  if ~isempty( I.FIELDS )
    for fn = fieldnames(I.FIELDS)'
      if isnumeric( I.FIELDS.(fn{1}) ) || islogical( I.FIELDS.(fn{1}) )
        if isfloat( I.FIELDS.(fn{1}) )
          I.FIELDS.(fn{1}) = padding( I.FIELDS.(fn{1}) , padsize , varargin{:} );
        elseif isinteger( I.FIELDS.(fn{1}) )
          I.FIELDS.(fn{1}) = padding( I.FIELDS.(fn{1}) , padsize , 'value', zeros(1,1,class(I.FIELDS.(fn{1})) ) );
        elseif islogical( I.FIELDS.(fn{1}) )
          I.FIELDS.(fn{1}) = padding( I.FIELDS.(fn{1}) , padsize , 'value', false );
        else
          I.FIELDS.(fn{1}) = padding( I.FIELDS.(fn{1}) , padsize , 'value', 0 );
        end
      end
    end
  end
  
end
