clc,clear
rand('state',7);
randn('state',7);

num_skeleton_points = 20;
d = 27; % configurfations: {25,30,50}
skeleton = lhsdesign_modified(num_skeleton_points,zeros(1,d),ones(1,d));
save(['skeletonD',num2str(d),'N',num2str(num_skeleton_points)],'skeleton');