#include "mex.h"
#include <stdlib.h>

#include "vtkPolyData.h"
#include "vtkCell.h"
#include "vtkCellData.h"
#include "vtkPointData.h"
mxArray *vtkPolyData2MESH( vtkPolyData *POLY ){
  const char  *names[] = {""};
  const int   dims[1] = {1};
  mxArray     *DATA;
  mxArray     *m;
  long        N, n;
  double      xyz[3];
  int         n_cols, c;
  int         n_fields, f;
  char        name[256];

  m   = mxCreateStructArray(1, dims, 0, names);

//NODES
  N= POLY->GetNumberOfPoints();
  if( N> 0) {
    DATA = mxCreateDoubleMatrix( N , 3 , mxREAL );
    for( n= 0; n<N ; n++ ) {
      POLY->GetPoint( n , xyz );
      for( c=0 ; c<3 ; c++ ){
        *( mxGetPr(DATA) + n + c*N )= xyz[c];
      }
    }
    mxAddField( m,    "xyz" );
    mxSetField( m, 0, "xyz", DATA );

    n_fields= POLY->GetPointData()->GetNumberOfArrays();
    for( f = 0 ; f < n_fields ; f++ ){
      sprintf( name , "xyz%s", POLY->GetPointData()->GetArray(f)->GetName() );
      if( !strcmp( name , "xyz(null)" ) ) {
        sprintf( name , "xyz%s", "NULL" );
      }
      n_cols= POLY->GetPointData()->GetArray(f)->GetNumberOfComponents();
      DATA = mxCreateDoubleMatrix( N , n_cols , mxREAL );
      for( n= 0; n<N ; n++ ) {
        for( c=0 ; c< n_cols ; c++ ){
          *( mxGetPr(DATA) + n + c*N )= POLY->GetPointData()->GetArray(f)->GetComponent(n,c);
        }
      }
      mxAddField( m,    name );
      mxSetField( m, 0, name, DATA );
    }
  }

//TRI
  N= POLY->GetNumberOfCells();
  if( N > 0 ) {
    DATA = mxCreateDoubleMatrix( N , 3 , mxREAL );
    for( n= 0; n<N ; n++ ) {
      for( c=0 ; c< POLY->GetCell(n)->GetNumberOfPoints() && c<3 ; c++ ){
        *( mxGetPr(DATA) + n + c*N )= POLY->GetCell(n)->GetPointId(c)+1;
      }
      for( ; c<3 ; c++ ){
        *( mxGetPr(DATA) + n + c*N )= 0;
      }
    }
    mxAddField( m,    "tri" );
    mxSetField( m, 0, "tri", DATA );

    n_fields= POLY->GetCellData()->GetNumberOfArrays();
    for( f = 0 ; f < n_fields ; f++ ){
      sprintf( name , "tri%s", POLY->GetCellData()->GetArray(f)->GetName() );
      n_cols= POLY->GetCellData()->GetArray(f)->GetNumberOfComponents();
      DATA = mxCreateDoubleMatrix( N , n_cols , mxREAL );
      for( n= 0; n<N ; n++ ) {
        for( c=0 ; c< n_cols ; c++ ){
          *( mxGetPr(DATA) + n + c*N )= POLY->GetCellData()->GetArray(f)->GetComponent(n,c);
        }
      }
      mxAddField( m,    name );
      mxSetField( m, 0, name, DATA );
    }
  }

  return(m);
}

// #include "vtkPolyDataReader.h"
// //void vtkPolyData2MESH_test(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
// void mexFuntion(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
//   
//   vtkPolyData *OBJETO = vtkPolyData::New();
//   vtkPolyDataReader *R = vtkPolyDataReader::New();
// 
//   R->SetFileName( "b.vtp" );
//   R->Update();
//   OBJETO->DeepCopy( R->GetOutput() );
//   R->Delete();
// 
//   plhs[0] = vtkPolyData2MESH( OBJETO );
// 
//   OBJETO->Delete();
// }
