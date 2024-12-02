function I = cat( dim , I , varargin )
%%falta hacer algo con INFO OTHERS y FIELDS

  I = remove_dereference( I );

  if isa( dim ,'I3D' )
    varargin{end+1} = I;
    varargin = varargin( [end 1:end-1] );
    I = dim;
    
    for k = 1:numel(varargin);
      I = cat2(4 , I , at( varargin{k},I ) );
    end
    return;
  end


  if ~isa(I,'I3D')
    error('I3D:Cat','The first argument has to be an I3D');
%     I1 = I3D(I1);
  end

  for k = 1:numel(varargin);
    I= cat2(dim,I,varargin{k});
  end

  function I1= cat2( dim , I1, I2 )

    if isempty(I1)
      if isa(I2,'I3D')
        I1 = I2;
      else
        error('I3D:Cat','concatenating with an empty???');
      end
      return;
    end
    
    if isempty( I2 )
      return;
    end
    
    for d = setdiff( 1:max(numel(size(I1)),numel(size(I2))) , dim )
      if size(I1,d) ~= size(I2,d)
        error('I3D:Cat','CAT arguments dimensions are not consistent in dimensions %d.',d)
      end
    end
    
    if isa(I2,'I3D')
      try
        I1.data   = cat( dim , I1.data         , I2.data         );
      catch
        I1.data   = cat( dim , double(I1.data) , double(I2.data) );
      end
      
      if dim < 5
        I1.LABELS = cat( dim , I1.LABELS , I2.LABELS );
      else
        if any( I2.LABELS(:) )
          warning('I3D:Cat','LABELS can not be cat along dim greater than 4');
        end
      end
      
%       try
%         I1.LABELS_INFO = [ I1.LABELS_INFO  I2.LABELS_INFO( numel(I1.LABELS_INFO)+1:numel(I2.LABELS_INFO) ) ];
%       end
%       I1.INFO   = { I1.INFO    I2.INFO   };
%       I1.OTHERS = { I1.OTHERS  I2.OTHERS };

      switch dim
        case 1
          if numel( I1.X ) > 1, b1 = ( I1.X(end)-I1.X(end-1) )/2;
          else                , b1 = 0.5;                         end
          if numel( I2.X ) > 1, b2 = ( I2.X(2)-I2.X(1) )/2;      
          else                , b2 = 0.5;                         end
          I1.X = [ I1.X , I2.X - I2.X(1) + I1.X(end) + b1 + b2 ];

        case 2
          if numel( I1.Y ) > 1, b1 = ( I1.Y(end)-I1.Y(end-1) )/2;
          else                , b1 = 0.5;                         end
          if numel( I2.Y ) > 1, b2 = ( I2.Y(2)-I2.Y(1) )/2;      
          else                , b2 = 0.5;                         end
          I1.Y = [ I1.Y , I2.Y - I2.Y(1) + I1.Y(end) + b1 + b2 ];

        case 3
          if numel( I1.Z ) > 1, b1 = ( I1.Z(end)-I1.Z(end-1) )/2;
          else                , b1 = 0.5;                         end
          if numel( I2.Z ) > 1, b2 = ( I2.Z(2)-I2.Z(1) )/2;      
          else                , b2 = 0.5;                         end
          I1.Z = [ I1.Z , I2.Z - I2.Z(1) + I1.Z(end) + b1 + b2 ];
          
        case 4
          if numel( I1.T ) > 1, b1 = ( I1.T(end)-I1.T(end-1) )/2;
          else                , b1 = 0.5;                         end
          if numel( I2.T ) > 1, b2 = ( I2.T(2)-I2.T(1) )/2;      
          else                , b2 = 0.5;                         end
          I1.T = [ I1.T , I2.T - I2.T(1) + I1.T(end) + b1 + b2 ];
          
      end

    else

      try
        I1.data   = cat( dim , I1.data         , I2         );
      catch
        I1.data   = cat( dim , double(I1.data) , double(I2) );
      end

      if dim < 5
        sz= size(I2); sz(5)=1; sz(sz==0)=1; sz = sz(1:4);
        I1.LABELS = cat( dim , I1.LABELS , zeros( sz , 'uint16') );
      end
      

      switch dim
        case 1
          if numel( I1.X ) > 1, b1 = ( I1.X(end)-I1.X(end-1) )/2;
          else                , b1 = 0.5;                         end
          I1.X = [ I1.X , I1.X(end) + (1:size(I2,1))*b1*2 ];

        case 2
          if numel( I1.Y ) > 1, b1 = ( I1.Y(end)-I1.Y(end-1) )/2;
          else                , b1 = 0.5;                         end
          I1.Y = [ I1.Y , I1.Y(end) + (1:size(I2,2))*b1*2 ];

        case 3
          if numel( I1.Z ) > 1, b1 = ( I1.Z(end)-I1.Z(end-1) )/2;
          else                , b1 = 0.5;                         end
          I1.Z = [ I1.Z , I1.Z(end) + (1:size(I2,3))*b1*2 ];
          
        case 4
          if numel( I1.T ) > 1, b1 = ( I1.T(end)-I1.T(end-1) )/2;
          else                , b1 = 0.5;                         end
          I1.T = [ I1.T , I1.T(end) + (1:size(I2,4))*b1*2 ];
          
      end
      
    end
      
  end

end
