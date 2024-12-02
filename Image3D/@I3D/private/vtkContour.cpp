#include "mex.h"
// #include "myMEX.h"

#include "vtkPolyData2MESH.h"
#include "vtkTriangleFilter.h"
#include "vtkCleanPolyData.h"
#include "vtkContourFilter.h"
#include "vtkDataArray.h"
#include "vtkDoubleArray.h"
#include "vtkStructuredPoints.h"
// #include "vtkStructuredPointsWriter.h"

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){

  const mxArray     *input;
  int         ndims;
  const int   *dims;
  void        *data;
  double      value;
  
//   value = myGetValue( prhs[1] );
  value = *( mxGetPr( prhs[1] ) );

                    
  vtkStructuredPoints *IMAGE;
  vtkDataArray        *D;
  
  IMAGE = vtkStructuredPoints::New();
  
  input = prhs[0];
  if( !strcmp( "I3D" , mxGetClassName(input) ) ){
 //   mexPrintf("aca\n");
    
    IMAGE->SetOrigin(  *(mxGetPr( mxGetField( input , 0 , "X") ) ) ,
                       *(mxGetPr( mxGetField( input , 0 , "Y") ) ) ,
                       *(mxGetPr( mxGetField( input , 0 , "Z") ) ) 
                     );
    IMAGE->SetSpacing( *(mxGetPr(mxGetField(input,0,"X"))+1)-*(mxGetPr(mxGetField(input,0,"X"))) ,
                       *(mxGetPr(mxGetField(input,0,"Y"))+1)-*(mxGetPr(mxGetField(input,0,"Y"))) ,
                       *(mxGetPr(mxGetField(input,0,"Z"))+1)-*(mxGetPr(mxGetField(input,0,"Z"))) 
                     );
    input = mxGetField( input , 0 , "data" );
  } else {
    IMAGE->SetOrigin(1,1,1);
    IMAGE->SetSpacing(1,1,1);
  }
  
  ndims = mxGetNumberOfDimensions( input );
  dims  = mxGetDimensions( input );
  data  = mxGetPr( input );
  if(ndims==1){  IMAGE->SetDimensions( dims[0] ,   1     ,   1     );  }
  if(ndims==2){  IMAGE->SetDimensions( dims[0] , dims[1] ,   1     );  }
  if(ndims >2){  IMAGE->SetDimensions( dims[0] , dims[1] , dims[2] );  }
  
  D = vtkDoubleArray::New();
    D->SetNumberOfTuples( IMAGE->GetNumberOfPoints() );  
    D->SetVoidArray( data , IMAGE->GetNumberOfPoints() , 1 );
  IMAGE->GetPointData()->SetScalars(D);
  
//   vtkStructuredPointsWriter *W;
//   W = vtkStructuredPointsWriter::New();
//     W->SetInput( IMAGE );
//     W->SetFileName("kk.vti");
//     W->Write();
//   W->Delete();
  
  vtkContourFilter *C;
  C = vtkContourFilter::New();
    C->SetInput( IMAGE );
    C->SetValue( 0 , value );
   
  vtkTriangleFilter   *TRIAN;
  TRIAN= vtkTriangleFilter::New();
    TRIAN->SetInput( C->GetOutput() );
    TRIAN->PassVertsOff();
    TRIAN->PassLinesOn();
  vtkCleanPolyData    *CLEAN;
  CLEAN = vtkCleanPolyData::New();
    CLEAN->SetInput( TRIAN->GetOutput() );
    CLEAN->PointMergingOn();
    CLEAN->ConvertLinesToPointsOn();
    CLEAN->ConvertPolysToLinesOn();
    CLEAN->ConvertStripsToPolysOn();
    CLEAN->Update();

  plhs[0] = vtkPolyData2MESH( CLEAN->GetOutput() );

  IMAGE->Delete();
  D->Delete();
  C->Delete();
  CLEAN->Delete();
  TRIAN->Delete();
}






