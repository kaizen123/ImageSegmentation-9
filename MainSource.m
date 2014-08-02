%resetting workspace
clear
close all
clc
%end of resetting

mainImage=imread('outdoor.jpg');
origImage=mainImage;
imageDimensions=size(mainImage);
greyImage=rgb2gray(mainImage);
[outputImage,PSNR,CR]=CompressDecompress(mainImage,1);
choice=input('Enter segmentation technique : \n 1:K-Means\n 2:Thresholding\n 3:Histogram baseed\n 4:Edge Detection\n');
Segmentation(outputImage,choice); 
 
 
