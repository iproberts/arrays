clc; clearvars; close all;

%% ------------------------------------------------------------------------
% 1. Create a uniform planar array using custom array object.
% -------------------------------------------------------------------------
num_rows = 2;
num_cols = 6;
upa = array.create(num_rows,num_cols);
upa.show_3d();
N = num_rows * num_cols;

%% ------------------------------------------------------------------------
% 2. Get the array response vector in some direction (az-el).
% -------------------------------------------------------------------------
az_deg = 15;
az = az_deg * pi / 180;
el = 0;
a = upa.get_array_response(az,el)

%% ------------------------------------------------------------------------
% 3. Create beamforming weights.
% -------------------------------------------------------------------------
w = ones(N,1);
w = conj(a);
w.' * a

%% -------------------------------------------------------------------------
% 4. Evaluate beamforming gain with these weights.
% -------------------------------------------------------------------------
az_deg = 45;
az = az_deg * pi / 180;
el = 0;
a = upa.get_array_response(az,el);
g = w.' * a;
abs(g)

%% -------------------------------------------------------------------------
% 5. Plot the array pattern.
% -------------------------------------------------------------------------
upa.set_weights(w);
upa.show_array_pattern_azimuth();
upa.show_polar_array_pattern_azimuth();

%% -------------------------------------------------------------------------
% 5. Plot the radiation pattern (array pattern in 3-D).
% -------------------------------------------------------------------------
upa.show_radiation_pattern();