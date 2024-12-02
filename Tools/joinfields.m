function S = joinfields( S , varargin )

  if isempty( S ), S = struct(); end
  if ~isstruct(S), error('it only work on a struct');        end
  if numel(S) > 1, error('it only work on a single struct'); end

  
  IGNORE_CASE           = false;
  OVERWRITE             = false;
  SIMILAR_FIELDS_NAMES  = false;
  
  
  to_remove = [];  i = 1;
  while i <= numel( varargin )
    if isstruct( varargin{i} )
      if numel( varargin{i} ) ~= 1
        error('it only work with single structs!!'); 
      end
      i = i+1;
      continue;
    end
    if ischar( varargin{i} )  &&  varargin{i}(1) ~= '$'
      if numel(varargin) == i, error('va a dar error!!'); end
      i = i+2;
      continue;
    end

    switch lower(varargin{i})
      case {'$ignorecase$','$ignore$','$ic$'}
        IGNORE_CASE = true;
      case {'$overwrite$','$over$','$ow$'}
        OVERWRITE = true;
      case {'$similar$' }
        SIMILAR_FIELDS_NAMES = true;
      otherwise
        error('option not understood   %s', varargin{i} );
    end
    to_remove(end+1) = i;
    i = i+1;
  end
  varargin( to_remove ) = [];

  
  extra_args = {};
  if IGNORE_CASE,           extra_args{end+1} = '$ignorecase$';  end
  if OVERWRITE,             extra_args{end+1} = '$overwrite$';   end
  if SIMILAR_FIELDS_NAMES,  extra_args{end+1} = '$similar$';     end
  


  
  original_fnames = fieldnames( S );
  while ~isempty( varargin )
    fn = varargin{1}; varargin(1) = [];

    switch class( fn )
      case 'char'
        
        value = varargin{1};  varargin(1) = [];
        
        if ~any( fn == '.' )
          
          fn = validate_field_name( fn );

          if ~isfield( S , fn )
            S.(fn) = value;
          elseif OVERWRITE
            S.(fn) = value;
          end
          
        else
          
          id = find( fn == '.' , 1 );

          fn1  = fn(    1:id-1 );  fn1 = validate_field_name( fn1 );
          fn2  = fn( id+1:end  );
          
          if ~isfield( S , fn1 )
            S.(fn1) = joinfields( struct , fn2 , value , extra_args{:} );
          else
            S.(fn1) = joinfields( S.(fn1) , fn2 , value , extra_args{:} );
          end
          
        end
        
      case 'struct'
        for f = fieldnames( fn )'
          
          value = fn.( f{1} );

          ff = validate_field_name( f{1} );

          if ~isfield( S , ff )

            S.(ff) = value;
            
          elseif isstruct( value ) 

            if isstruct( S.(ff) )
              S.(ff) = joinfields( S.(ff) , value , extra_args{:} );
            else
              error('trying to join a struct to a non-struct');
            end

          end

        end
        
    end
  end

  
  function f = validate_field_name( f )
    if SIMILAR_FIELDS_NAMES

      n = numel(f);
        
      if IGNORE_CASE
        idd = find( cellfun( @(s) strncmpi( f , s , n ) ,  original_fnames  ) );
        if numel(idd) == 1,  f = original_fnames{idd}; end
      else
        idd = find( strcnmp( f , original_fnames , n ) );
        if numel(idd) == 1,  f = original_fnames{idd}; end
      end


    elseif IGNORE_CASE
      
      idd = find( strcmpi( f , original_fnames ) );
      if numel(idd) == 1, f = original_fnames{idd}; end
      
    end
  end

end
