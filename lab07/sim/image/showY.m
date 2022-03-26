function [  ] = showY( filename, width, height )
%showY Summary of this function goes here
%   Detailed explanation goes here
fileID = fopen(filename);
A = fread(fileID);
fclose(fileID);
B = A(1:width*height);
C = reshape(B, width, height);

image(C'/256*64);
axis equal tight;
axis off;
colormap(gray);

end
