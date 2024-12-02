function intEditor = Edit( fn )


  intEditor = handle(awtcreate('com.mathworks.mlwidgets.interactivecallbacks.InteractiveCallbackEditor', ...
    'Ljava.awt.Rectangle;Ljava.lang.String;Ljava.lang.String;', ...
    java.awt.Rectangle(35,70,260,680),...
    fn , '' ) );

  % Display the editor
  intEditor.setVisible(true);
  
end

