#include "myMEX.h"
#include "vtkPolyData2MESH.h"

#include "vtkPolyData.h"
#include "vtkPoints.h"
#include "vtkCellArray.h"
#include "vtkCleanPolyData.h"

#define add(p1,p2,p3,p4)    FACES->InsertNextCell(3);   \
                            FACES->InsertCellPoint(p1); \
                            FACES->InsertCellPoint(p2); \
                            FACES->InsertCellPoint(p3); \
                            FACES->InsertNextCell(3);   \
                            FACES->InsertCellPoint(p3); \
                            FACES->InsertCellPoint(p4); \
                            FACES->InsertCellPoint(p1); 

#define V(i,j,k)  V[ (i) + (j)*I + (k)*IJ ]
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){ ALLOCATES();

  real            *DX, *DY, *DZ;
  int             n, i, j ,k, I, J, K, I1, J1, K1, IJ, I1J1, I1J1K1;
  int             a, b, c, d, e, f, g, h;
  int             *ids;
  int             last_id;
  int             add_pI, add_nI, add_pJ, add_nJ, add_pK, add_nK;


  
  I1 = myNumel(prhs[1]);
  J1 = myNumel(prhs[2]);
  K1 = myNumel(prhs[3]);


  if( mySize( prhs[0] , 0 )+1 != I1 ){ myErrMsgTxt("numel(DX) Coordinates do not coincide with size(IM,1) + 1."); }
  if( mySize( prhs[0] , 1 )+1 != J1 ){ myErrMsgTxt("numel(DY) Coordinates do not coincide with size(IM,2) + 1."); }
  if( mySize( prhs[0] , 2 )+1 != K1 ){ myErrMsgTxt("numel(DZ) Coordinates do not coincide with size(IM,3) + 1."); }

  
  mxLogical       *V;
  V = (mxLogical *) mxGetData( prhs[0] );
  

  DX = myGetPr(prhs[1]);
  DY = myGetPr(prhs[2]);
  DZ = myGetPr(prhs[3]);
  
  I = I1-1;
  J = J1-1;
  K = K1-1;
  IJ   = I*J;
  I1J1 = I1*J1;
  I1J1K1 = I1J1*K1;
  

  
  ids = (int *) mxMalloc( I1J1K1 * sizeof( int ) );
  for( n = 0 ; n < I1J1K1 ; n++ ){
    ids[n] = 0;
  }
  
  
//   n = 0;
//   for( k = 0 ; k < K1 ; k++ ){
//   for( j = 0 ; j < J1 ; j++ ){
//   for( i = 0 ; i < I1 ; i++ ){
//     VERTS -> InsertPoint( n++ , DX[i] , DY[j] , DZ[k] );
//   }}}
//   POLY->SetPoints( VERTS );


  last_id = 0;
  n = 0;
  
  vtkPoints       *VERTS  = vtkPoints::New();
  vtkCellArray    *FACES  = vtkCellArray::New();
  for( k = 0 ; k < K ; k++ ){
  for( j = 0 ; j < J ; j++ ){
  for( i = 0 ; i < I ; i++ ){

    if( !V[n++] ){ continue; }

    add_pI = 0;
    add_nI = 0;
    add_pJ = 0;
    add_nJ = 0;
    add_pK = 0;
    add_nK = 0;


    if( i == 0    ||  !V( i-1 , j , k ) ){    add_pI = 1;   }
    if( i == I-1  ||  !V( i+1 , j , k ) ){    add_nI = 1;   }
    if( j == 0    ||  !V( i , j-1 , k ) ){    add_pJ = 1;   }
    if( j == J-1  ||  !V( i , j+1 , k ) ){    add_nJ = 1;   }
    if( k == 0    ||  !V( i , j , k-1 ) ){    add_pK = 1;   }
    if( k == K-1  ||  !V( i , j , k+1 ) ){    add_nK = 1;   }


    if( add_pI || add_nI || add_pJ || add_nJ || add_pK || add_nK ){

//       a = ( i     )  + ( j     )*I1 + ( k     )*I1J1;
//       b = ( i + 1 )  + ( j     )*I1 + ( k     )*I1J1;
//       c = ( i     )  + ( j + 1 )*I1 + ( k     )*I1J1;
//       d = ( i + 1 )  + ( j + 1 )*I1 + ( k     )*I1J1;
//       e = ( i     )  + ( j     )*I1 + ( k + 1 )*I1J1;
//       f = ( i + 1 )  + ( j     )*I1 + ( k + 1 )*I1J1;
//       g = ( i     )  + ( j + 1 )*I1 + ( k + 1 )*I1J1;
//       h = ( i + 1 )  + ( j + 1 )*I1 + ( k + 1 )*I1J1;
      a = ( i     )  + ( j     )*I1 + ( k     )*I1J1;
      b = a + 1;
      c = a + I1;
      d = c + 1;
      e = a + I1J1;
      f = e + 1;
      g = e + I1;
      h = g + 1;

      
      if( !ids[a] ){
        VERTS -> InsertPoint( last_id , DX[ i    ] , DY[ j    ] , DZ[ k    ] );
        ids[a] = last_id++;
      }
      if( !ids[b] ){
        VERTS -> InsertPoint( last_id , DX[ i +1 ] , DY[ j    ] , DZ[ k    ] );
        ids[b] = last_id++;
      }
      if( !ids[c] ){
        VERTS -> InsertPoint( last_id , DX[ i    ] , DY[ j +1 ] , DZ[ k    ] );
        ids[c] = last_id++;
      }
      if( !ids[d] ){
        VERTS -> InsertPoint( last_id , DX[ i +1 ] , DY[ j +1 ] , DZ[ k    ] );
        ids[d] = last_id++;
      }
      if( !ids[e] ){
        VERTS -> InsertPoint( last_id , DX[ i    ] , DY[ j    ] , DZ[ k +1 ] );
        ids[e] = last_id++;
      }
      if( !ids[f] ){
        VERTS -> InsertPoint( last_id , DX[ i +1 ] , DY[ j    ] , DZ[ k +1 ] );
        ids[f] = last_id++;
      }
      if( !ids[g] ){
        VERTS -> InsertPoint( last_id , DX[ i    ] , DY[ j +1 ] , DZ[ k +1 ] );
        ids[g] = last_id++;
      }
      if( !ids[h] ){
        VERTS -> InsertPoint( last_id , DX[ i +1 ] , DY[ j +1 ] , DZ[ k +1 ] );
        ids[h] = last_id++;
      }
      //mexPrintf("h: %d  ... ids[h] :  %d\n", h , ids[h] ); myFlush();


      if( add_pI ){    add( ids[c] , ids[a] , ids[e] , ids[g] );   }
      if( add_nI ){    add( ids[b] , ids[d] , ids[h] , ids[f] );   }

      if( add_pJ ){    add( ids[a] , ids[b] , ids[f] , ids[e] );   }
      if( add_nJ ){    add( ids[d] , ids[c] , ids[g] , ids[h] );   }

      if( add_pK ){    add( ids[a] , ids[c] , ids[d] , ids[b] );   }
      if( add_nK ){    add( ids[e] , ids[f] , ids[h] , ids[g] );   }

    }
    
  }}}

  vtkPolyData     *POLY   = vtkPolyData::New();
  POLY->SetPoints( VERTS );
  POLY->SetPolys(  FACES );
  

  vtkCleanPolyData    *CLEAN = vtkCleanPolyData::New();
  CLEAN->SetInput( POLY );
  CLEAN->ToleranceIsAbsoluteOn();
  CLEAN->SetAbsoluteTolerance(1e-10);
  CLEAN->ConvertLinesToPointsOn();
  CLEAN->ConvertPolysToLinesOn();
  CLEAN->ConvertStripsToPolysOn();
  CLEAN->PointMergingOn();
  
  
  CLEAN->Update();
  plhs[0]= vtkPolyData2MESH( CLEAN->GetOutput() );  
  
  EXIT:
    mxFree( ids );
    CLEAN->Delete();
    POLY->Delete();
    VERTS->Delete();
    FACES->Delete();
    
    myFreeALLOCATES();
  
}



