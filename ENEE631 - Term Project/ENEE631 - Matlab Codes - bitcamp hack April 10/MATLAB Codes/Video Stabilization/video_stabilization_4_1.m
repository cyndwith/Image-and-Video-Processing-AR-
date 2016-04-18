clear all;clc;close all;
%function[]=video_stabilization_4_1(filename)
    filename = 'shaky_original.mp4';
    noFrames = 80;
    windowSize = 10;
    trajectory = zeros([3 noFrames]);
    smooth_trajectory = zeros([3 noFrames]); 
    %temp_trajectory = zeros([3 noFrames]); 
    transformation = zeros([3 noFrames]);
    trajectory(:,1) = zeros([3 1]);
    smooth_trajectory(:,1) = zeros([3 1]);
    %temp_trajectory(:,1) = zeros([3 1]);
    transformation(:,1) = zeros([3 1]);
    
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
    ImSize = size(v);
    Tcumm=eye(3);
    %Temp1 = zeros(3);
    for i=2:noFrames
        A=v(:,:,:,i-1); B=v(:,:,:,i);
    
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
        transformation(1,i) = Temp1(3,1,i);
        transformation(2,i) = Temp1(3,2,i);
        if (Temp1(2,1,i)~=0 || Temp1(1,1,i)~=0)
            transformation(3,i) = atan(double(Temp1(2,1,i))/double(Temp1(1,1,i)));
        else
            transformation(3,i) = 0;
        end
        x(i) = transformation(1,i);
        y(i) = transformation(2,i);
        %avgTemp1(3,1) = newX(i);
        %avgTemp1(3,2) = newY(i);
        trajectory(1,i) = trajectory(1,i) + transformation(1,i);
        trajectory(2,i) = trajectory(2,i) + transformation(2,i);
        trajectory(3,i) = trajectory(3,i) + transformation(3,i);
        
        Tcumm=Tcumm*Temp1(:,:,i);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %for i = 1:numel(T)
            [xlim, ylim] = outputLimits(Trans, [1 ImSize(2)], [1 ImSize(1)]);
        %end

        % xlim,ylim

        % Find the minimum and maximum output limits
        xMin = min([1; xlim(:)]);
        xMax = max([ImSize(2); xlim(:)]);

        yMin = min([1; ylim(:)]);
        yMax = max([ImSize(1); ylim(:)]);

        % Width and height of panorama.
        width  = round(xMax - xMin);
        height = round(yMax - yMin);

        xLimits = [xMin xMax];  
        yLimits = [yMin yMax];

        %outputView = imref2d([height width],xLimits,yLimits);
        outputView=imref2d(size(B));
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%% Smoothing trajectory %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        count = 0;
        temp_trajectory = zeros([3 1]);
        for k = -windowSize:1:-1
            j = i+k;
            if j >= 1
                j
                temp_trajectory(1) = temp_trajectory(1) + transformation(1,j);
                temp_trajectory(2) = temp_trajectory(2) + transformation(2,j);
                temp_trajectory(3) = temp_trajectory(3) + transformation(3,j);
                count=count+1;
            end
        end
        smooth_trajectory(:,i) = temp_trajectory./count;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         %avgTcum(i) = mean(Tcumm);
%         if(i>windowSize)
%             avgT(:,:,i) = eye(3,3)./windowSize;%mean(Temp1(:,:,i-windowSize:i),3);
%             for k = 1:1:windowSize
%                 avgT(:,:,i) = avgT(:,:,i)*Temp1(:,:,i-k);
%             end
%         else
%             avgT(:,:,i) = eye(3,3)./i;%mean(Temp1(:,:,1:i),3);
%             for k = 1:1:i
%                 avgT(:,:,i) = avgT(:,:,i)*Temp1(:,:,k);
%             end
%         end
        newTrajectory = transformation(:,i)+smooth_trajectory(:,i)-trajectory(:,i);
        newT = consTransform(newTrajectory);
        %newT = Temp1(:,:,i) + (avgT(:,:,i) - Tcumm);
        %newT(3,3) = 1;
        %newX(i) = newTrajectory(1);
        %newY(i) = newTrajectory(2);
        newX(i) = newT(3,1);
        newY(i) = newT(3,2);
        BTrans=imwarp(B,affine2d(newT),'OutputView',outputView);
        %maskIm = zeros(size(A));
        %maskIm(size(A,1)/4:size(A,1)*(3/4),size(A,2)/4:size(A,2)*(3/4),:)=...
         %   ones(size(A,1)/2+1,size(A,2)/2+1,3);
        %figure;imshow(maskIm);
        BTrans = imresize(BTrans,[video.Height,video.Width]);
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
    subplot(1,2,1);
    plot(trajectory(1,:));hold on;
    plot(smooth_trajectory(1,:));hold on;
    legend('Trajectory','smooth_Trajectory');
    subplot(1,2,2);
    plot(trajectory(2,:));hold on;
    plot(smooth_trajectory(2,:));
    legend('Trajectory','smooth_Trajectory');
    figure(3);
    plot(newX);hold on;
    plot(newY);legend('newX','newY');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



