		
M = O.model; % REPLACE "O" WITH MODEL VARIABLE
D = size(M);
% Dataset dimensions
y0 = D(1);
x0 = D(2);
z0 = D(3);

% First coord
y1 = randi([0 y0-100]);
x1 = randi([0 x0-100]);
%z1 = randi([0 (z0-20)]); %(z0-[size of ROI in Z]) will stop the ROI being
...too close to the edge of the dataset. Can use this for y1 and x1 also
    
while O.model(y1,x1) == 0
    y1 = randi([0 y0]);
    x1 = randi([0 x0]);
    if O.model(y1,x1) == 1
        break
    end
end


x1
y1


% Last coord
y2 = y1+100;
x2 = x1+100;
% z2 = z1+20
