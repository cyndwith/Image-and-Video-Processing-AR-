clear all;clc;close all;
%function[]=video_stabilization_4_1(filename)
    filename = 'shaky_original.mp4';
    noFrames = 00;
    windowSize = 20;
    video = VideoReader(filename);
    count=floor(video.FrameRate*video.Duration);
    v=zeros(video.Height,video.Width,3,count);
    u=zeros(video.Height,video.Width,3,count);
    count=0;
    while hasFrame(video)
        count=count+1;
        v(:,:,:,count)=readFrame(video);
    end
    v=uint8(v);
    Tcumm=eye(3);
    %Temp1 = zeros(3);
    for i=1:noFrames
        A=v(:,:,:,i); B=v(:,:,:,i+1);
    
        Apoints=detectFASTFeatures(rgb2gray(A),'MinContrast',0.1);
        Bpoints=detectFASTFeatures(rgb2gray(B),'MinContrast',0.1);
    
        [Afeatures,Apoints]=extractFeatures(rgb2gray(A),Apoints);
        [Bfeatures,Bpoints]=extractFeatures(rgb2gray(B),Bpoints);
    
        matchPairs= matchFeatures(Afeatures, Bfeatures);
        Apoints=Apoints(matchPairs(:,1),:);
        Bpoints=Bpoints(matchPairs(:,2),:);
    
        % figure; showMatchedFeatures(A,B,Apoints,Bpoints);
    
        Trans=estimateGeometricTransform(Bpoints,Apoints,'affine');
        temp=Trans.T;
        Temp1(:,:,i) = cvexTformToSRT(temp);
        x(i) = Temp1(3,1,i);
        y(i) = Temp1(3,2,i);
       
        
        %avgTemp1(3,1) = newX(i);
        %avgTemp1(3,2) = newY(i);
        Tcumm=Tcumm*Temp1(:,:,i);
        outputView=imref2d(size(B));
        %avgTcum(i) = mean(Tcumm);
        if(i>windowSize)
            avgT(:,:,i) = mean(Temp1(:,:,i-windowSize:i),3);
        else
            avgT(:,:,i) = mean(Temp1(:,:,1:i),3);
        end
        newT = Temp1(:,:,i) + (avgT(:,:,i) - Tcumm);
        newX(i) = newT(3,1);
        newY(i) = newT(3,2);
        BTrans=imwarp(B,affine2d(newT),'OutputView',outputView);
        %maskIm = zeros(size(A));
        %maskIm(size(A,1)/4:size(A,1)*(3/4),size(A,2)/4:size(A,2)*(3/4),:)=...
         %   ones(size(A,1)/2+1,size(A,2)/2+1,3);
        %figure;imshow(maskIm);
        u(:,:,:,i)=BTrans;%autoCrop(BTrans);%.*uint8(maskIm));
        %size( u(:,:,:,i))
        %u(:,:,:,i)=autoCrop_Matlab(BTrans)
        % figure;showMatchedFeatures(A,BTrans,Apoints,BStabPoints);
    
    end
    figure;
    vidOBJ = VideoWriter('stabilized.avi');
    open(vidOBJ);
    for i=1:noFrames
        i
        subplot(1,2,1);imshow(uint8(v(:,:,:,i)));
        subplot(1,2,2);imshow(uint8(u(:,:,:,i)));
        %figure(2);imshow(wFrame.cdata);
        wFrame = getframe;
        wFrame = imresize(wFrame.cdata,[480 640]);
        writeVideo(vidOBJ,wFrame);
        drawnow;
    end
    close(vidOBJ);
    figure(2);
    %subplot(1,2,1);
    plot(x);hold on;
    plot(y);hold on;
    %subplot(1,2,2);
    plot(newX);hold on;
    plot(newY);
    legend('x','y','newX','newY');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



