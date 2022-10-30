clear; close all; clc;
%%%%%%%%%%%%%%%%%%%%%%%% Compression %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Reading the image 

I_RGB = imread('ankit.jpg');
figure();
subplot(121);imshow(I_RGB);title('RGB');

% I_cropped=imcrop(I_RGB,[150 500 7 7]);
%conversion of RGB image to YCbCr

I_ycbcr = rgb2ycbcr(I_RGB);
subplot(122);imshow(I_ycbcr);title('YCbCr');

y=I_ycbcr(:,:,1);  %all rows and colums in 1st plane i.e Y
cb=I_ycbcr(:,:,2); %all rows and colums in 2nd plane i.e Cb
cr=I_ycbcr(:,:,3); %all rows and colums in 3rd plane i.e Cr

figure();subplot(131);imshow(y);title('Luma');
subplot(132);imshow(cb);title('Cb');
subplot(133);imshow(cr);title('Cr');

%chroma sub-sampling

cb_down=imresize(cb,0.5,'bilinear');
cr_down=imresize(cr,0.5,'bilinear');

figure();subplot(121);imshow(cb_down);title('cb down');
subplot(122);imshow(cr_down);title('Cr down');

%converting uint8 to double 

y=double(y);
cb_down=double(cb_down);
cr_down=double(cr_down);

%Shifting the blocks to be centered around 0 rather than 128:
for i = 1:height(y)
    for j = 1:width(y)
        y(i,j) = y(i,j)-128;
    end
end
for i = 1:height(cb_down)
    for j = 1:width(cb_down)
        cb_down(i,j) = cb_down(i,j)-128;
    end
end
for i = 1:height(cr_down)
    for j = 1:width(cr_down)
        cr_down(i,j) = cr_down(i,j)-128;
    end
end

y;
cb_down;
cr_down;

figure();subplot(131);imshow(y);title('Shifted Luma');
subplot(132);imshow(cb);title('Shifted Cb');
subplot(133);imshow(cr);title('Shifted Cr');

% zero padding

% Convert the luminance height and width to multiple of 8
if rem(size(y,1),8)~=0
    y=[y;zeros(8-rem(size(y,1),8),size(y,2))];
end
if rem(size(y,2),8)~=0
    y=[y zeros(size(y,1),8-rem(size(y,2),8))];
end

% Convert the chrominance height and width to multiple of 8
if rem(size(cb_down,1),8)~=0
    cb_down=[cb_down;zeros(8-rem(size(cb_down,1),8),size(cb_down,2))];
end
if rem(size(cb_down,2),8)~=0
    cb_down=[cb_down zeros(size(cb_down,1),8-rem(size(cb_down,2),8))];
end
if rem(size(cr_down,1),8)~=0
    cr_down=[cr_down;zeros(8-rem(size(cr_down,1),8),size(cr_down,2))];
end
if rem(size(cr_down,2),8)~=0
    cr_down=[cr_down zeros(size(cr_down,1),8-rem(size(cr_down,2),8))];
end

%dividing the image into blocks and applying dct2 transform

y_dct = blockproc(y,[8 8],@(blkStruct) dct2(blkStruct.data));
cb_down_dct = blockproc(cb_down,[8 8],@(blkStruct) dct2(blkStruct.data));
cr_down_dct = blockproc(cr_down,[8 8],@(blkStruct) dct2(blkStruct.data));

figure();
subplot(131);imshow(y_dct);title('Dct Luma');
subplot(132);imshow(cb_down_dct);title('Dct Cb');
subplot(133);imshow(cr_down_dct);title('Dct Cr');

% Initialization of quantization matrices for chrominance and luminance

% Quant luminance

Q_y = [ 16 11 10 16 24 40 51 61 ; 12 12 14 19 26 58 60 55;
14 13 16 24 40 57 69 56; 14 17 22 29 51 87 80 62;
18 22 37 56 68 109 103 77; 24 35 55 64 81 104 113 92;
49 64 78 87 103 121 120 101; 72 92 95 98 112 100 103 99 ] ;

% Quant chrominance

Q_c = [ 17 18 24 47 99 99 99 99 ; 18 21 26 66 99 99 99 99 ;
24 26 56 99 99 99 99 99; 47 66 99 99 99 99 99 99;
99 99 99 99 99 99 99 99; 99 99 99 99 99 99 99 99;
99 99 99 99 99 99 99 99; 99 99 99 99 99 99 99 99 ] ;

%Quantization of Luminance and Chrominance:
quant_y = @(blockStruct) round((blockStruct.data)./Q_y);     
quant_c = @(blockStruct) round((blockStruct.data)./Q_c);      

y_dct_quant = blockproc(y_dct, [8 8], quant_y);
cb_down_dct_quant = blockproc(cb_down_dct, [8 8], quant_c);
cr_down_dct_quant = blockproc(cr_down_dct, [8 8], quant_c);

figure();
subplot(131);imshow(y_dct_quant);title('Dct Luma quantized');
subplot(132);imshow(cb_down_dct_quant);title('Dct Cb quantized');
subplot(133);imshow(cr_down_dct_quant);title('Dct Cr quantized');

%Zig-zag coding

zigzag_y=zigzag(y_dct_quant);
zigzag_cb=zigzag(cb_down_dct_quant);
zigzag_cr=zigzag(cr_down_dct_quant);

%Run Length Encoding

y_rle=rle(zigzag_y);
cb_rle=rle(zigzag_cb);
cr_rle=rle(zigzag_cr);


%%%%%%%%%%%%%%%%%%%%%%%%%% Decompression %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Inverse run-length encoding

y_irle=irle(y_rle);
cb_irle=irle(cb_rle);
cr_irle=irle(cr_rle);

%Inverse zigzag encoding

y_izigzag=izigzag(y_irle,size(y_dct_quant,1),size(y_dct_quant,2));
cb_izigzag=izigzag(cb_irle,size(cb_down_dct_quant,1),size(cb_down_dct_quant,2));
cr_izigzag=izigzag(cr_irle,size(cr_down_dct_quant,1),size(cr_down_dct_quant,2));

%Dequantization 

y_dequant = blockproc(y_izigzag,[8 8],@(blockStruct) round((blockStruct.data).*Q_y));
cb_dequant = blockproc(cb_izigzag,[8 8],@(blockStruct) round((blockStruct.data).*Q_c));
cr_dequant = blockproc(cr_izigzag,[8 8],@(blockStruct) round((blockStruct.data).*Q_c));

figure();
subplot(131);imshow(y_dequant);title('dequantized y');
subplot(132);imshow(cb_dequant);title('dequantized cb');
subplot(133);imshow(cr_dequant);title('dequantized cr');

% Applying idct      

y_idct = blockproc(y_dequant,[8 8],@(blockStruct) idct2(blockStruct.data));
cb_idct = blockproc(cb_dequant,[8 8],@(blockStruct) idct2(blockStruct.data));
cr_idct = blockproc(cr_dequant,[8 8],@(blockStruct) idct2(blockStruct.data));

figure();
subplot(131);imshow(y_idct);title('idct y');
subplot(132);imshow(cb_idct);title('idct cb');
subplot(133);imshow(cr_idct);title('idct cr');

%Shifting the blocks back
for i = 1:height(y_idct)
    for j = 1:width(y_idct)
        y_idct(i,j) = y_idct(i,j)+128;
    end
end
for i = 1:height(cb_idct)
    for j = 1:width(cb_idct)
        cb_idct(i,j) = cb_idct(i,j)+128;
    end
end
for i = 1:height(cr_idct)
    for j = 1:width(cr_idct)
        cr_idct(i,j) = cr_idct(i,j)+128;
    end
end

% Chroma up sampling

cb_up_sampling = imresize(cb_idct,2,'bilinear');
cr_up_sampling = imresize(cr_idct,2,'bilinear');

figure();
subplot(121);imshow(cb_up_sampling);title('Up-sampled Cb');
subplot(122);imshow(cr_up_sampling);title('Up-sampled Cr');

%Reconstructing Luminance and Chrominance of same size:
y_reconstruct = y_idct(1:height(y), 1:width(y));
cb_up_reconstruct = cb_up_sampling(1:height(cb), 1:width(cb));
cr_up_reconstruct = cr_up_sampling(1:height(cr), 1:width(cr));

% YCbCr reconstruction

YCbCr_reconstruct(:,:,1)=y_reconstruct;
YCbCr_reconstruct(:,:,2)=cb_up_reconstruct;
YCbCr_reconstruct(:,:,3)=cr_up_reconstruct;
YCbCr_reconstruct =uint8(YCbCr_reconstruct);
figure();
imshow(YCbCr_reconstruct);
title('Reconstructed YCbCr');

% Convert ycbcr back to RGB

I_reconstructed=uint8(ycbcr2rgb(YCbCr_reconstruct));

figure();
imshow(I_reconstructed);
title('Reconstructed Image');