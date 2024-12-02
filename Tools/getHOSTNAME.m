function [ hn_ , LongHostName_ ] = getHOSTNAME()
  persistent hn
  persistent LongHostName

  if isempty( hn )
    [ state , hn ] = system('hostname');

    if state
       if ispc, hn = getenv('COMPUTERNAME');
       else,    hn = getenv('HOSTNAME');
       end
    end

    if isempty( hn )
      [state,hn] = system('hostname -s');
    end

    hn = strtrim( hn );
    hn = strrep( strrep( hn , char(10) , '' ) , char(13) , '' );
  end

  if isempty( LongHostName ) && nargout > 1
    [state,LongHostName] = system('hostname');
    if state, LongHostName = ''; end
    LongHostName = strrep( strrep( LongHostName , char(10) , '' ) , char(13) , '' );
    LongHostName_ = LongHostName;
  end

  
  if nargout == 0
    fprintf('%s\n',hn);
    return;
  end
  
  hn_ = hn;
  
end