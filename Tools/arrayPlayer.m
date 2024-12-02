classdef arrayPlayer < handle
  properties ( Access = private , Hidden = false )
    Callback;
    Elements;
    ElementsPerSecond;
  end
  properties ( Access = private , Hidden = true )
    State;  %'Stop' 'Play' 'Loop' 'Bounce'
    Timer;
    lastElement;
    timeFrom;
  end

  methods ( Hidden = true )
    function aP = arrayPlayer( FCN , Elements , varargin )
      if isequal( FCN , 'demo' )
        if nargin < 2 || isempty( Elements ), Elements = 1:200; end
        
        TODAY = now;
        figure;
        hL = line( NaN , NaN , 'marker','.');

        hFPS = eEntry( 'Position',[1 1 10 10],'small','range',[0 200],'iValue',25 );
        hFPS.callback_fcn =  @(x)updateFPS(x);        
        
        FCN      = @(e)demoFCN(e);
        varargin = { 'ElementsPerSecond' , 25 };
        
        set( gcf , 'CloseRequestFcn' , @(h,e)eval('delete(gcf);delete(aP)') );
      end
      function updateFPS(fps)
        vline( ( now - TODAY )* 3600 * 24 );
        set( aP , 'ElementsPerSecond' , fps );
      end
      function demoFCN(e)
        ct = ( now - TODAY )* 3600 * 24;
        xd = get( hL , 'xdata' ); xd = [ xd(:) ; ct ];
        yd = get( hL , 'ydata' ); yd = [ yd(:) ; e  ];
        set( hL , 'xdata' , xd  , 'ydata' , yd );
      end

      
      aP.Callback = FCN;
      aP.Elements = Elements;
      
      [varargin,i,aP.ElementsPerSecond] = parseargs(varargin ,'fps','ElementsPerSecond','$DEFS$', min( numel( aP.Elements ) , 25 ) );
      
      existingTimers = timerfindall( 'Tag' , 'arrayPlayer_Time' );
      if isempty( existingTimers )
        existingTimers = 0;
      else
        existingTimers = get( existingTimers ,'Name' );
        if ~iscell( existingTimers ), existingTimers = { existingTimers }; end
        existingTimers = regexp( existingTimers , '[^_]*_(\d)*','tokens','once' );
        existingTimers = cellfun( @(c)c{1} , existingTimers , 'un',0);
        existingTimers = [ 0 ; str2double(  existingTimers ) ];
      end
      currentTimeName = sprintf( 'TimerForArrayPlayer_%d' , max(existingTimers)+1 );

      aP.Timer = timer( 'BusyMode'         ,'drop'          ,...
                        'ExecutionMode'    ,'fixedSpacing'  ,...
                        'Name'             ,currentTimeName ,...
                        'ObjectVisibility' , 'off'          ,...
                        'Period'           , 0.03           ,...
                        'StartDelay'       , 0              ,...
                        'TasksToExecute'   , Inf            ,...
                        'Tag'              , 'arrayPlayer_Time' ,...
                        'StopFcn'          , @(h,e) stop( aP )  ,...
                        'ErrorFcn'         , @(h,e) stop( aP )  ,...
                        'TimerFcn'         , @(h,e)evaluateFCN(aP) );
                      
      aP.lastElement = -1;
      aP.timeFrom = now;
      aP.State = 'Stop';
    end
    
    function delete( aP )
      %fprintf( 'deleting aP %s\n' , get(aP.Timer,'Name') );
      if strcmp( get( aP.Timer , 'Running' ) , 'on' )
        stop( aP.Timer );
      end
      delete( aP.Timer );
    end
    function clear( aP ),    delete( aP ); end
    function clearvar( aP ), delete( aP ); end
  end
  
  methods ( Access = public , Hidden = false )

    function x = get( aP , prop )
      switch lower(prop)
        case {'callback'}
          x = aP.Callback;
        case {'elements'}
          x = aP.Elements;
        case {'elementspersecond','fps','eps'}
          x = aP.ElementsPerSecond;
        otherwise
          error('Unaccessible property?');
      end
    end
    
      
    function set( aP , varargin )
      newCallback          = [];
      newElementsPerSecond = [];
      newElements          = [];
      while numel(varargin)
        switch lower(varargin{1})
          case {'callback'}
            if aP.State(1) ~= 'S', error('cannot set a new Callback while running'); end
            newCallback           = varargin{2};
          case {'elements'}
            if aP.State(1) ~= 'S', error('cannot set new elements while running'); end
            newElements           = varargin{2};
          case {'elementspersecond','fps','eps'}
            newElementsPerSecond  = varargin{2};
            newElementsPerSecond  = max( newElementsPerSecond , 1e-7 );
        end
        varargin(1:2) = [];
      end
      if ~isempty( newCallback )
        aP.Callback = newCallback;
      end
      if ~isempty( newElements )
        aP.Elements = newElements;
      end
      if ~isempty( newElementsPerSecond )
        if aP.State(1) ~= 'S'
          ctime = now;
          idx = max( round( ( ctime - aP.timeFrom ) * 3600*24*aP.ElementsPerSecond ) , 1 );
          
          aP.timeFrom = ctime - idx/( 3600*24*newElementsPerSecond );
        end
        aP.ElementsPerSecond = newElementsPerSecond;
        
        %set( aP.Timer , 'Period' , 1/(aP.ElementsPerSecond*2) );
      end
    end
    
    
    function play( aP )
      if aP.State(1) ~= 'S', return; end
      
      aP.State = 'Play';
      aP.timeFrom = now;
      try, feval( aP.Callback , aP.Elements( 1 ) ); aP.lastElement = 1; end
      if numel( aP.Elements ) > 1, start( aP.Timer ); end
    end
    function loop( aP )
      if aP.State(1) ~= 'S', return; end
      
      aP.State = 'Loop';
      aP.timeFrom = now;
      try, feval( aP.Callback , aP.Elements( 1 ) ); aP.lastElement = 1; end
      if numel( aP.Elements ) > 1, start( aP.Timer ); end
    end
    function bounce( aP )
      if aP.State(1) ~= 'S', return; end
      
      aP.State = 'Bounce';
      aP.timeFrom = now;
      try, feval( aP.Callback , aP.Elements( 1 ) ); aP.lastElement = 1; end
      if numel( aP.Elements ) > 1, start( aP.Timer ); end
    end
    function stop( aP )
      if strcmp( get( aP.Timer , 'Running' ) , 'on' ), stop( aP.Timer ); end
      aP.State = 'Stop';
      aP.lastElement = -1;
    end
  end
  
  
  
  
  methods ( Access = private , Hidden = true )
    function evaluateFCN( aP )
      try,
        ctime = now;
        idx = max( round( ( ctime - aP.timeFrom ) * 86400 * aP.ElementsPerSecond ) , 1 );
        n = numel( aP.Elements );
        
        switch aP.State(1)
          case 'S'
            return;

          case 'P'
            if idx > n, stop( aP ); return; end
            
          case 'B'
            idx = rem( idx - 1 , n*2 - 2 ) + 1;
            idx = min( 2*n - idx , idx );
          
          case 'L'
            idx = rem( idx - 1 , n ) + 1;
            
        end
        
        if idx == aP.lastElement, return; end
        
        try, feval( aP.Callback , aP.Elements( idx ) ); aP.lastElement = idx; end
      catch
        fprintf(2,'some error evaluating... but continue playing...');
      end
    end
  end
  
end
