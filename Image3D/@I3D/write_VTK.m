function write_VTK( I , fn , mode )
  
  if nargin < 3
    mode = 'interp';
  end

  fid = fopen( fn , 'w' );
  if fid <= 0, error('cannot open file "%s".',fn); end
  
  CLEANUP = onCleanup(@()fclose(fid));

  sz = [ numel(I.X) , numel(I.Y) , numel(I.Z) ];
  N  = prod(sz);
  switch lower( mode )
    case {'interp'}
      field_type = 'POINT_DATA';
      xyz = ndmat( I.X , I.Y , I.Z);
    case {'flat'}
      field_type = 'CELL_DATA';
      sz = sz + 1;
      xyz = ndmat( dualVector(I.X) , dualVector(I.Y) , dualVector(I.Z) );
  end
  xyz = transform( xyz , I.SpatialTransform );
  xyz = xyz.';
  
  fprintf(fid,'# vtk DataFile Version 4.0\n');
  fprintf(fid,'I3D\n');
  fprintf(fid,'BINARY\n');
  fprintf(fid,'DATASET STRUCTURED_GRID\n');
  fprintf(fid,'DIMENSIONS %d %d %d\n', sz );
  fprintf(fid,'POINTS %d double\n', prod( sz ) );
  fwrite( fid , xyz , class(xyz) , 0 , 'b' );  
  fprintf(fid,'%s %d\n' , field_type , N );
  fprintf(fid,'FIELD field 1\n');
  fprintf(fid,'VALUE 1 %d %s\n' , N , class_as_c( I.data ) );
  fwrite( fid , I.data , class(I.data) , 0 , 'b' );  

end

function c = class_as_c( x )
  switch class(x)
    case 'double',  c = 'double';
    case 'single',  c = 'float';
    case 'uint64',  c = 'unsigned_long';
    case 'int64',   c = 'long';
    case 'uint32',  c = 'unsigned_int';
    case 'int32',   c = 'int';
    case 'uint16',  c = 'unsigned_short';
    case 'int16',   c = 'short';
    case 'uint8',   c = 'unsigned_char';
    case 'int8',    c = 'char';
    case 'logical', c = 'bool';
  end
end
