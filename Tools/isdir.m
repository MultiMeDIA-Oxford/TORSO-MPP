function result = isdir(dirpath)


  SCP = regexp( dirpath , '(^.*@.*?):(.*)' , 'tokens' );
  if isempty(SCP)
    
    result = exist(dirpath,'dir') == 7;
    
  else
    
    [status,result] = system( sprintf( 'ssh %s ''if [ -d "%s" ]; then echo "EXIST__DIR"; else echo "MISSING__DIR"; fi''' , SCP{1}{1} , SCP{1}{2} ) );
    result = ~isempty( regexp(result, '\<EXIST__DIR\>' ) ); %strncmp( result , 'EXIST' , 5 );
    
  end



end