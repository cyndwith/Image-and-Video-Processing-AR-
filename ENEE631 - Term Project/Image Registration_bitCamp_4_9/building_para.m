clc; clear all;
Scene = imageSet('images');
n=Scene.Count;
n=5;
Im = cell(n,1); Imc = cell(n,1);wIm=cell(n,1);
for i=1:n
    
    Im{i} = rgb2gray(read(Scene, i));
    Imc{i}= read(Scene, i);
    
end

ImSize = size(Im{1});
points = detectSURFFeatures(Im{1});
[features, points] = extractFeatures(Im{1},points);

T(1) = projective2d(eye(3));

for i = 2:n
    
    prevPoints = points;
    prevFeatures = features;
    
    points = detectSURFFeatures(Im{i});
    [features, points] = extractFeatures(Im{i},points);
    
    matchPairs = matchFeatures(features,prevFeatures,'Unique',true,'MatchThreshold',1);
    
    currMatchPoints = points(matchPairs(:,1),:);
    prevMatchPoints = prevPoints(matchPairs(:,2),:);
    
    T(i)= estimateGeometricTransform(currMatchPoints, prevMatchPoints,'projective','Confidence',99.9,'MaxNumTrials',2000);
    T(i).T = T(i).T*T(i-1).T;
end


for i = 1:size(T,2)
    [xlim(i,:),ylim(i,:)] = outputLimits(T(i),[1 ImSize(1)],[1 ImSize(2)]);
end

avgXLim = mean(xlim,2);
[~,idx] = sort(avgXLim);
centerIdx = floor((numel(T)+1)/2);
centerImageIdx  = idx(centerIdx);

Tinv = invert(T(centerImageIdx));

for i = 1:numel(T)
    T(i).T = Tinv.T * T(i).T;
end

for i = 1:numel(T)
    [xlim(i,:), ylim(i,:)] = outputLimits(T(i), [1 ImSize(2)], [1 ImSize(1)]);
end

xlim,ylim

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

panoramaView = imref2d([height width],xLimits,yLimits);
t=imwarp(Imc{1},T(1),'OutputView',panoramaView);
for i=2:n
    
    wIm{i} = imwarp(Imc{i}, T(i),'OutputView',panoramaView);
    t=image_stitch(t,wIm{i});
    
end
figure(1);
imshow(uint8(t));hold on;X=320;Y=500;
figure(2);
imCROP = autoCrop(uint8(t));
imshow(uint8(imCROP));
figure(3);
imCROP = autoCrop_Matlab(uint8(imCROP));
imshow(uint8(imCROP));

% plot(X,Y,'ro');hold off;
% [x1,y1]=worldToIntrinsic(panoramaView,X,Y);
%figure(2);imshow(uint8(Imc{1})); hold on;
%plot(y1,x1,'ro');hold on;
%plot(300,400,'ro');

