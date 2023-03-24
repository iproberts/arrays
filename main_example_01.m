clc; clearvars; close all;

%% ------------------------------------------------------------------------
% 1. Create a uniform linear array using custom array object.
% -------------------------------------------------------------------------
N = 8;
ula = array.create(N);
ula.show_3d();

%% ------------------------------------------------------------------------
% 2. Get the array response vector in some direction (az-el).
% -------------------------------------------------------------------------
az_deg = 15;
az = az_deg * pi / 180;
el = 0;
a = ula.get_array_response(az,el)

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
a = ula.get_array_response(az,el);
g = w.' * a;
abs(g)

%% -------------------------------------------------------------------------
% 5. Plot the array pattern.
% -------------------------------------------------------------------------
ula.set_weights(w);
ula.show_array_pattern_azimuth();
ula.show_polar_array_pattern_azimuth();
