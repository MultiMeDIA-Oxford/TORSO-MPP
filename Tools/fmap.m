function O = fmap( F , I , varargin )

  if iscell(I)
    try
      O = builtin( 'cellfun' , F , I , varargin{:} );
    catch
      try
        O = builtin( 'cellfun' , F , I , varargin{:} ,'UniformOutput',false );
      catch
        O = builtin( 'cellfun' , @(varargin)safeEVAL(F,varargin{:}) , I , varargin{:} ,'UniformOutput',false );
      end
    end
  else
    try
      O = builtin( 'arrayfun' , F , I , varargin{:} );
    catch
      try
        O = builtin( 'arrayfun' , F , I , varargin{:} ,'UniformOutput',false );
      catch
        O = builtin( 'arrayfun' , @(varargin)safeEVAL(F,varargin{:}) , I , varargin{:} ,'UniformOutput',false );
      end
        
    end
  end

  function o = safeEVAL(FCN,varargin)
    o = false;
    try
      feval(FCN,varargin{:});
      o = true;
    end
  end
  
end
