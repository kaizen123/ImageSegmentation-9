function [  ] = Segmentation( inputImage,option)

switch option
    case 1
        KMeans(inputImage);
    case 2
        Threshold(inputImage);
    case 3
        Histogram(inputImage);
    case 4
        EdgeDetection(inputImage);
        
    otherwise
        display('Incorrect choice');
        
end


end


function [] = KMeans(inputImage)
modImage = double(reshape(inputImage,size(inputImage,1)*size(inputImage,2),size(inputImage,3)));
clusters= kmeans(modImage,5);
figure('name','KMeans');
imagesc(reshape(clusters,size(inputImage,1),size(inputImage,2)));
%imshow(inputImage)
end


function [] = Threshold(inputImage) %Using Otsu thresholding

level = graythresh(inputImage);
BW = im2bw(inputImage,level);
figure();
imshow(BW);

end


function []=Histogram(inputImage) %Bimodal
tempHist=hist(inputImage,256); 
histogram=sum(tempHist'); 
figure('name','Histogram Plot');
plot(tempHist,'r');
localMaxima=find(histogram==max(histogram)); 
bw=roicolor(inputImage,localMaxima,255);
figure('name','Histogram Bitmap');
imshow(bw);
end


function []=EdgeDetection(inputImage)
inputImage=im2double(inputImage);
choice=input('Enter your choice :\n1:Prewitt\n2:Roberts\n3:Laplacian of a Guassian(LoG)\n');
filterOutput=[];
switch choice
    case 1
        filterOutput=edge(inputImage,'prewitt');
        figure();
        imshow(filterOutput);
    case 2
        filterOutput=edge(inputImage,'roberts');
        figure();
        imshow(filterOutput);
    case 3
        filterOutput=edge(inputImage,'log');
        figure();
        imshow(filterOutput);

    otherwise
        display('\nWrong Choice\n');
end
end


