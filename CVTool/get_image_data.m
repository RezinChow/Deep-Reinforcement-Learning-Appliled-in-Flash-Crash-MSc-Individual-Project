%% Get image data
% clear the work area and screen
clear,clc,close all
%% Calibration between picture and curve

im2=imread('gepre3.jpg'); %input image
im2=rgb2hsv(im2);
a=0;
b=0;
c=0;

%filter on for selected area
for a = 4:710
    for b = 5:1430
        if im2(a,b,1) < 0.42 || im2(a,b,1) > 0.75 || im2(a,b,2) < 0.2 || im2(a,b,2) >0.9999 || im2(a,b,3) < 0.2 || im2(a,b,3) > 0.999
            im2(a,b,1) = 0;
            im2(a,b,2) = 0;
            im2(a,b,3) = 0;
        end
    end
end
im2= hsv2rgb(im2);
im = imcomplement(im2);

im=rgb2gray(im);%Detect grayscale changes
thresh = graythresh(im);%Get binarization threshold
im=im2bw(im,thresh);%binarization img
set(0,'defaultfigurecolor','w')
imshow(im)
[y,x]=find(im==0);%figure out the "locate points" (x,y) 
y=max(y)-y;%Convert screen coordinates to right-handed Cartesian coordinates
y=fliplr(y);%Flip the array left and right
plot(x,y,'r.','Markersize', 2);
disp('Please click on the two vertices of the actual coordinate frame in Figrure ');
[Xx,Yy]=ginput(2);
min_x=input('min value of x');
max_x=input('max value of y');
min_y=input('min value of x');
max_y=input('max value of y');
x=(x-Xx(1))*(max_x-min_x)/(Xx(2)-Xx(1))+min_x;
y=(y-Yy(1))*(min_y-max_y)/(Yy(2)-Yy(1))+max_y;
plot(x,y,'r.','Markersize', 2);
axis([min_x,max_x,min_y,max_y])%Set the coordinate range according to the input
title('Unprocessed scatter plot from the original image')
%% Convert scattered points to usable curves

%(1) In the scatter plot, one x may correspond to several y <---> Keep the y value between mean()-std() to mean()+std() and average
%(2) The front and last segments of the curve have greater interference <---> Remove the front (such as 5%) and back 5% of the curve as a whole
%(3) The top and bottom segments of the curve have greater interference <---> Remove the upper 10% and lower 10% of the curve as a whole

%Parameter preset
rate_x=0.01;%Deletion ratio of the front and last segments of the curve
rate_y=0.01;%Delete ratio of the top and bottom of the curve

[x_uni,index_x_uni]=unique(x);%Find out how many different x coordinates there are

x_uni(1:floor(length(x_uni)*rate_x))=[];%Remove the x coordinate of the previous rate_x (such as 5%)
x_uni(floor(length(x_uni)*(1-rate_x)):end)=[];
index_x_uni(1:floor(length(index_x_uni)*rate_x))=[];
index_x_uni(floor(length(index_x_uni)*(1-rate_x)):end)=[];
[mxu,~]=size(x_uni);
[mx,~]=size(x);
for ii=1:mxu
    if ii==mxu
        ytemp=y(index_x_uni(ii):mx);
    else
        ytemp=y(index_x_uni(ii):index_x_uni(ii+1));
    end
    %Remove outliers with excessive variance
    threshold1=mean(ytemp)-std(ytemp);
    threshold2=mean(ytemp)+std(ytemp);
    ytemp(find(ytemp<threshold1))=[];%Delete anomalous points in a section of y corresponding to the same x
    ytemp(find(ytemp>threshold2))=[];
    %Delete points closer to the top and bottom
    thresholdy=(max_y-min_y)*rate_y;%y coordinate threshold
    ytemp(find(ytemp>max_y-thresholdy))=[];
    ytemp(find(ytemp<min_y+thresholdy))=[];
    %The remaining y is averaged
    y_uni(ii)=mean(ytemp);
end
%To further delete these empty points
x_uni(find(isnan(y_uni)))=[];
y_uni(find(isnan(y_uni)))=[];

figure,plot(x_uni,y_uni)
axis([min_x,max_x,min_y,max_y])
% Output the finally extracted x and y data
curve_val(1,:)=x_uni';
curve_val(2,:)=y_uni;
%% fitting (not used yet)
[p,s]=polyfit(curve_val(1,:),curve_val(2,:),4);
[y_fit,DELTA]=polyval(p,x_uni,s);
figure,plot(x_uni,y_fit)
axis([min_x,max_x,min_y,max_y])
%% map these data to Specified time step
x_step = [];
y_value= [];
for i = 0:400
    [~,Index] = min(abs(i-x_uni));
    x_step(end+1) = i;
    y_value(end+1)= y_uni(Index);
end
