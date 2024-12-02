function o = in( I , in , varargin )

  I = remove_dereference( I );

  if isa(in,'I3D')
    % %                     X  -> in
    % %                     Y  -> in
    % %                     Z  -> in
    % %      SpatialTransform  -> in
    % %                  data  -> I.data interpolated en in
    % %                LABELS  -> I.LABELS interpolated en in
    % %                FIELDS  -> numericos: I  interpolated en in ,  i3d:  los mismos
    % %                     T  -> I
    % %           LABELS_INFO  -> I
    % %        ImageTransform  -> I
    % %  SpatialInterpolation  -> I
    % %          BoundaryMode  -> I
    % %          BoundarySize  -> I
    % %          OutsideValue  -> I
    % %     TimeInterpolation  -> I
    % %             LANDMARKS  -> I
    % %              CONTOURS  -> I
    % %                  INFO  -> I
    % %                OTHERS  -> I
    % %          GRID_PROPERTIES  -> []
    
    
    o   = I;
    o.GRID_PROPERTIES = [];
    
    o.X = in.X;
    o.Y = in.Y;
    o.Z = in.Z;
    o.SpatialTransform = in.SpatialTransform;

    
    
    [varargin,aliasing] = parseargs(varargin,'ALIASing','$FORCE$',1);
    
    if aliasing
      I = spatialScale(I,in,'circular'); 
    end
    
    if isempty( I.data )
      o.data = [];
    else
      o.data = InterpPointsOn3DGrid( ...
                  I.data , I.X , I.Y , I.Z , ...
                  in.data                  , ...
                  'omatrix', I.SpatialTransform , ...
                  I.SpatialInterpolation , ...
                  'outside_value' , I.OutsideValue , ...
                  I.BoundaryMode  , I.BoundarySize , ...
                  varargin{:} );
      o.data = reshape( o.data , [ numel(in.X) numel(in.Y) numel(in.Z) numel(I.T) size(I.data,5) size(I.data,6) size(I.data,7)] );
    end

    if isempty( I.LABELS )
      o.LABELS = [];
    elseif any(I.LABELS(:))
      o.LABELS = uint16( InterpPointsOn3DGrid( ...
              I.LABELS , I.X , I.Y , I.Z , ...
              in.data , ...
              varargin{:} , ...
              'omatrix', I.SpatialTransform , ...
              'nearest' , ...
              'outside_value' , 0 , ...
              'value' ) ...
              );
      o.LABELS = reshape( o.LABELS , [ numel(o.X) numel(o.Y) numel(o.Z) numel(o.T) ] );
    else
      o.LABELS = zeros( [ numel(o.X) numel(o.Y) numel(o.Z) numel(o.T) ] ,'uint16');
    end
    
%     if isfield(I,'FIELDS')  &&   ~isempty( I.FIELDS )
%       for fn = fieldnames(I.FIELDS)'
%         if isnumeric( I.FIELDS.(fn{1}) )
%           o.FIELDS.(fn{1}) = Interp3DGridOn3DGrid( ...
%                                 I.FIELDS.(fn{1}) , I.X , I.Y , I.Z , ...
%                                 in.X , in.Y , in.Z , ...
%                                 'omatrix', I.SpatialTransform , ...
%                                 'nmatrix', in.SpatialTransform , ...
%                                 I.SpatialInterpolation , ...
%                                 'outside_value' , I.OutsideValue , ...
%                                 I.BoundaryMode  , I.BoundarySize , ...
%                                 varargin{:} );
%         end
%       end
%     end
    
   
  elseif isnumeric( in ) || isa( in , 'SamplePoints' )
    
    o = at( I , in , varargin );
    
  else
    
    error('Incorrect object.');
            
  end
 
end