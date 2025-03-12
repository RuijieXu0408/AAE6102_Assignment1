clc;clear;close all;

load("PosErr_Sky.mat");
load("PosErr_Urban.mat");
load("PosErr_Opensky_kf.mat");
load("PosErr_Urban_kf.mat");

figure;
plot(1:39,PosErr_sky,1:39,PosErr_Urban,1:39,PosErr_Opensky_kf,...
    1:39,PosErr_Urban_kf);
ylabel("Error (m)");
title("Positioning Error");
legend("WLS Opensky","WLS Urban","EKF Opensky","EKF Urban");


