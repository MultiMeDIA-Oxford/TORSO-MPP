
A = dual(rand(3));
B = dual(randn(5));
c = dual(5);

%%

X = dual(randn(5)); F = @(X)A*X(1:3,1:3);
X = dual(randn(1,1,54,3,2)); F = @(X)cumprod(X);
X = dual(randn(3)); F = @(X)rdivide(exp(X),c);
X = dual(randn(3)); F = @(X)power( cos(X) , cos(X) );
X = dual(randn(1,1,1,2,3,4)); F = @(X)bsxfun(@times,X,permute(X,6:-1:1));
X = dual(diag([1000 1 1e-3])*randn(3)); F = @(X)fro2(X);
X = dual(randn(2,5,7,2)); F = @(X)fro(X);


di = NumericalDiff( F , double(X) , 'i' );
dd = NumericalDiff( F , double(X) , 'd' );
% dd = NumericalDiff( F , double(X) , 'd' , 'plot' ,'gt',di);
maxnorm( di , dd )

P = dual( double(X) , randn(size(X)) );
maxnorm( dd * dpart(P(:)) , vec( dpart( F(P) ) ) )
