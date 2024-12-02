function OPZ_Roll(dir)

  aa= ancestortool( hittest , 'axes' );
  if aa 
%     set(aa,'XColor',[.65 0 0],'YColor',[0 .65 0],'ZColor',[0 0 .65]);

    camroll(aa,dir*10);
  end
end
