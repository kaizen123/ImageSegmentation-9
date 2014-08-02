function [ finalOutput PSNR CompressionRatio ] = CompressDecompress( mainImage,scaleFactor )

redValues=mainImage(:,:,1);
greenValues=mainImage(:,:,2);
blueValues=mainImage(:,:,3);
yValues=0.299*(redValues-greenValues)+greenValues+0.114*(blueValues-greenValues);
%figure();
%imshow(yValues);



[rows columns numberOfColorBands] = size(mainImage);
cropLimit=min(rows,columns);
croppedImage = mainImage(1:cropLimit,1:cropLimit);
scaleFactor=1024/cropLimit;
scaledImage=imresize(croppedImage,scaleFactor);
fi
% imshow(scaledImage);

defaultQuantizationMatrix = [
            16 11 10 16  24  40  51  61
            12 12 14 19  26  58  60  55
            14 13 16 24  40  57  69  56
            14 17 22 29  51  87  80  62
            18 22 37 56  68 109 103  77
            24 35 55 64  81 104 113  92
            49 64 78 87 103 121 120 101
            72 92 95 98 112 100 103 99];
        
zigzagScanIndex=[11,12,21,31,22,13,14,23,32,41,51,42,33,24,15,16,25,34,43,52,61,71,62,53,44,35,26,17,18,27,36,45,54,63,72,81,82,73,64,55,46,37,28,38,47,56,65,74,83,84,75,66,57,48,58,67,76,85,86,77,68,78,87,88];
 


 
huffmanCodesDC={'00','010','011','100','101','110','1110','11110','111110','1111110','11111110','111111110'};
huffmanCodesAC={'00','01','100','1011','11010','1111000','11111000','1111110110','1111111110000010','1111111110000011';
                '1100','11011','1111001','111110110','11111110110','1111111110000100','1111111110000101','1111111110000110','1111111110000111','1111111110001000';
                '11100','11111001','1111110111','111111110100','1111111110001001','1111111110001010','1111111110001011','1111111110001100','1111111110001101','1111111110001110';
                '111010','111110111','111111110101','1111111110001111','1111111110010000','1111111110010001','1111111110010010','1111111110010011','1111111110010100','1111111110010101';
                '111011','1111111000','1111111110010110','1111111110010111','1111111110011000','1111111110011001','1111111110011010','1111111110011011','1111111110011100','1111111110011101';
                '1111010','11111110111','1111111110011110','1111111110011111','1111111110100000','1111111110100001','1111111110100010','1111111110100011','1111111110100100','1111111110100101';
                '1111011','111111110110','1111111110100110','1111111110100111','1111111110101000','1111111110101001','1111111110101010','1111111110101011','1111111110101100','1111111110101101';
                '11111010','111111110111','1111111110101110','1111111110101111','1111111110110000','1111111110110001','1111111110110010','1111111110110011','1111111110110100','1111111110110101';
                '111111000','111111111000000','1111111110110110','1111111110110111','1111111110111000','1111111110111001','1111111110111010','1111111110111011','1111111110111100','1111111110111101';
                '111111001','1111111110111110','1111111110111111','1111111111000000','1111111111000001','1111111111000010','1111111111000011','1111111111000100','1111111111000101','1111111111000110';
                '111111010','1111111111000111','1111111111001000','1111111111001001','1111111111001010','1111111111001011','1111111111001100','1111111111001101','1111111111001110','1111111111001111';
                '1111111001','1111111111010000','1111111111010001','1111111111010010','1111111111010011','1111111111010100','1111111111010101','1111111111010110','1111111111010111','1111111111011000';
                '1111111010','1111111111011001','1111111111011010','1111111111011011','1111111111011100','1111111111011101','1111111111011110','1111111111011111','1111111111100000','1111111111100001';
                '11111111000','1111111111100010','1111111111100011','1111111111100100','1111111111100101','1111111111100110','1111111111100111','1111111111101000','1111111111101001','1111111111101010';
                '1111111111101011','1111111111101100','1111111111101101','1111111111101110','1111111111101111','1111111111110000','1111111111110001','1111111111110010','1111111111110011','1111111111110100';
                '1111111111110101','1111111111110110','1111111111110111','1111111111111000','1111111111111001','1111111111111010','1111111111111011','1111111111111100','1111111111111101','1111111111111110'};
cont=0;
qOutput=zeros(1024,1024);
dctOutput=zeros(1024,1024);
qMatrix=repmat(defaultQuantizationMatrix,128);
% qMatrix2=qMatrix./2;
% qMatrix3=qMatrix.*8;
qMatrixforQuant=qMatrix.*scaleFactor;


row=1;
while (row<=1024)
    col=1;
    while(col<=1024)
        input=scaledImage(row:row+7,col:col+7);
        dctOutput(row:row+7,col:col+7)=dct2(input);
        col=col+8;
        cont=cont+1;
    end
    row=row+8;
end

%dctOutput=dct2(scaledImage); %We avoid bulk dct and do it blockwise
qOutput=round(dctOutput./qMatrixforQuant);


row=1;
direction=0; %1-->top to bottom , 0 ---> bottom to top
blkCount=0
zigzagscan=zeros(128*128,64);
while(row<=1024)
    col=1;
    while(col<=1024)
        blkCount=blkCount+1;
        %logic for traversing the block
        cnt=0;
        while(cnt<64)
           cnt=cnt+1;
           index=zigzagScanIndex(cnt);
           x=floor(index/10);
           y=index-(x*10);
           zigzagscan(blkCount,cnt) = qOutput(row+x-1,col+y-1);
        end
        col=col+8;
    end
    row=row+8;
end


blkCount=1;
maxTupleCount=-1;
maxTupleVectorSize=200;
rleOutput=zeros(128*128,maxTupleVectorSize);
previousDCCoeff=0;
while(blkCount<=128*128)
    runLevelTuples=[];
    runLevelTuplesFinal=[];

    nonZeroIndices=find(zigzagscan(blkCount,:)~=0);
    nonZeroIndicesCount=length(nonZeroIndices);
    

    %adding the dc coefficient
    if(length(nonZeroIndices)>0 && nonZeroIndices(1)==1)
        runLevelTuples=cat(2,runLevelTuples,zigzagscan(blkCount,nonZeroIndices(1)));
        %dpcm of dc coeff.
        if(blkCount~=1)
           runLevelTuples(1)=previousDCCoeff-runLevelTuples(1); 
        end
        previousDCCoeff= zigzagscan(blkCount,nonZeroIndices(1));
    else 
        runLevelTuples(1)=previousDCCoeff;
        previousDCCoeff=0;
        
    end
    
           
    i=2;
    while(i<=nonZeroIndicesCount)
        run=nonZeroIndices(i)-nonZeroIndices(i-1)-1;
        runLevelTuples=cat(2, runLevelTuples, run,zigzagscan(blkCount,nonZeroIndices(i)));
        i=i+1;
    end
    %adding eob
    runLevelTuples=cat(2,runLevelTuples,255,255);
    
    if(length(runLevelTuples)>maxTupleCount)
        maxTupleCount=length(runLevelTuples);
    end

    runLevelTuplesFinal=cat(2,runLevelTuples,zeros(1,maxTupleVectorSize-length(runLevelTuples)));
    rleOutput(blkCount,:)=runLevelTuplesFinal;
    blkCount=blkCount+1;
end
    
    %end of huffman generation
        
    %Huffman Coding
    
    blkIndex=1;
    huffManOutput=cell(128*128,maxTupleVectorSize);
    while(blkIndex<=128*128)
        constHuffman={};
        index=2;
        %dc encoding
        dcComp=rleOutput(blkIndex,1);
        if(dcComp==0)
            dcCategory=0;
        else
            dcCategory=floor(log2(abs(dcComp)))+1;
        end
        
        if(dcComp>0)
            baseCode=dec2bin(dcComp);
        else
            if(dcComp<0)
                baseCode=dec2bin(dcComp+(2^dcCategory)-1,dcCategory);
            else
                baseCode='0';
            end
        end
        
        valueCode=huffmanCodesDC(dcCategory+1);
        constHuffman(1)=cellstr(baseCode);
        constHuffman(2)=cellstr(valueCode);
        
        %ac encoding
        while(index<=maxTupleVectorSize)
            run=rleOutput(blkIndex,index);
            
            c=rleOutput(blkIndex,index+1);
            category= floor(log2(abs(c)))+1;
            if(run==255 && c==255)
                constHuffman=cat(2,constHuffman,'1010');
                break;
            else
                if(run>=15)
                    run=15;
                end
                constHuffman=cat(2,constHuffman,huffmanCodesAC(run+1,category+1));
            end
            index=index+2;
        end
        s=size(constHuffman);
        constHuffman=cat(2,constHuffman,cell(1,maxTupleVectorSize-s(2)));
        huffManOutput(blkIndex,:)=constHuffman(1,1:200);
        blkIndex=blkIndex+1;
    end
    
    blkIndex=1;
    totalBits=0;
    while(blkIndex<=128*128)
        index=1;
        while(index<=maxTupleVectorSize)
            totalBits=totalBits+size(huffManOutput(blkIndex,index));
            if(strcmp(huffManOutput(blkIndex,index),'1010'))
                break;
            end
            index=index+1;
        end
        blkIndex=blkIndex+1;
    end
    
    CompressionRatio=totalBits/(1024*1024*8);
    %Start of Decoding 
    
    %Huffman Decoding
    
    blkIndex=1;
    huffManDecodeOutput=zeros(128*128,maxTupleVectorSize);
    while(blkIndex<=128*128)
        huffManDecode=[];
        encString=huffManOutput(blkIndex,:);
        %dc decoding
        category=lookup(huffmanCodesDC,encString(2));
        estValue=bin2dec(encString(1));
        if(estValue<(2^(category-1)))
            estValue=estValue+1-2^category;
        end
        huffManDecode(1)=estValue;
        %ac decoding
        index=3;
        while(index<=maxTupleVectorSize)
            if(strcmp(encString(index),'1010'))
                huffManDecode=cat(2,huffManDecode,[255 255]);
                break;
            else
                [index1,index2]=lookup(huffmanCodesAC,encString(index));
                huffManDecode=cat(2,huffManDecode,[index1-1 index2-1]);
            end
            index=index+1;
        end
        s=size(huffManDecode);
        huffManDecode=cat(2,huffManDecode,zeros(1,maxTupleVectorSize-s(2)));
        
        huffManDecodeOutput(blkIndex,:)=huffManDecode(1,1:200);
        blkIndex=blkIndex+1;
    end
    %Run-length decoding
    
    blkCount=1;
    
    constZigZagMatrix=zeros(128*128,64);
    while(blkCount<=128*128)
        constructedZigZag=[];
        runLengthTuples=rleOutput(blkCount,:);
        if(blkCount==1)
            constructedZigZag(1)=runLengthTuples(1);
        else
            constructedZigZag(1)=constZigZagMatrix(blkCount-1,1)-runLengthTuples(1);
        end
        
        i=2;
        while(i<=maxTupleVectorSize)
            
            if(runLengthTuples(i)<255) %regular tuples
                constructedZigZag=cat(2,constructedZigZag,zeros(1,runLengthTuples(i)));
                constructedZigZag=cat(2,constructedZigZag,runLengthTuples(i+1));
            else %eob pad with zeros
                constructedZigZag=cat(2,constructedZigZag,zeros(1,64-length(constructedZigZag)));
                break;
            end
            
            i=i+2;
        end
        constZigZagMatrix(blkCount,:)=constructedZigZag;
        blkCount=blkCount+1;
    end
      
    
%De-zigzag

row=1;
blkIndex=1;
dezigzagOutput=zeros(1024,1024);
while(row<=1024)
    col=1;
    while(col<=1024)
        i=1;
        while(i<=64)
            index=zigzagScanIndex(i);
            x=floor(index/10);
            y=index-x*10;
            dezigzagOutput(row+x-1,col+y-1)=constZigZagMatrix(blkIndex,i);
            i=i+1;
        end
        blkIndex=blkIndex+1;
        col=col+8;
    end
    
    row=row+8; 
end

%De-Quantize
dequantizeOutput=dezigzagOutput.*qMatrixforQuant;
dequantizeOutput=dequantizeOutput./100;

%Inverse-DCT

finalOutput=zeros(1024,1024);
row=1;
while (row<=1024)
    col=1;
    while(col<=1024)
        input=dequantizeOutput(row:row+7,col:col+7);
        finalOutput(row:row+7,col:col+7)=idct2(input);
        col=col+8;
        cont=cont+1;
    end
    row=row+8;
end

%finalOutput=idct2(dequantizeOutput); %We avoid bulk inverse-DCT and do it
%blockwise
%

figure('name','CompressedImage');
imshow(finalOutput);


%PSNR calculation

diff=(double(finalOutput.*100)-double(scaledImage)).^2;
MSE=sum(diff(:))./(1024*1024);
PSNR=10*log10(255*255/MSE);


end

function [index1,index2]=lookup(input,key)
    rowCount=size(input(:,1));
    colCount=size(input(1,:));
    index1=1;
    while(index1<=rowCount)
        index2=1;
        while(index2<=colCount)
            if(strcmp(input(index1,index2),key))
                break;
            end
            index2=index2+1;
        end
        index1=index1+1;
    end
end