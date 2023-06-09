classdef array < matlab.mixin.Copyable
    properties
        num_antennas = 0; % number of antenna elements in array
        x = []; % x coordinates of array elements (in wavelengths)
        y = []; % y coordinates of array elements (in wavelengths)
        z = []; % z coordinates of array elements (in wavelengths)
        weights; % element weights (complex)
        marker = 'kx'; % element marker when plotting
    end
    methods(Static)
        function obj = create(N,M,plane)
            % CREATE Creates an antenna array object.
            %
            % Usage:
            %  obj = array.create()
            %  obj = array.create(N)
            %  obj = array.create(N,M)
            %  obj = array.create(N,[])
            %  obj = array.create(N,M,plane)
            %  obj = array.create(N,[],plane)
            %
            % Args:
            %  N: (optional) number of elements in the array; or number of
            %  rows in a planar array if a second argument is passed
            %  M: (optional) a string specifying which axis to create the 
            %  linear array; or number of columns in a planar array
            %  plane: (optional) a string specifying the plane to create
            %  the planar array in (either 'xz', 'xy', or 'yz'); if not
            %  passed, 'xz' will be used
            %
            % Returns:
            %  obj: an array object
            if nargin < 1
                obj = array();
            elseif nargin < 2
                obj = array(N);
            elseif nargin < 3
                obj = array(N,M);
            else
                obj = array(N,M,plane);
            end
        end
    end
    methods
        function obj = array(N,M,plane)
            % ARRAY Creates an instance of an array object.
            % 
            % Usage:
            %  obj = ARRAY()
            %  obj = ARRAY(N)
            %  obj = ARRAY(N,M)
            %  obj = ARRAY(N,[])
            %  obj = ARRAY(N,M,plane)
            %  obj = ARRAY(N,[],plane)
            % 
            % Args:
            %  N: (optional) number of elements in the array; or number of
            %  rows in a planar array if a second argument is passed
            %  M: (optional) number of columns in a planar array
            %  plane: (optional) a string specifying the plane to create
            %  the planar array in (either 'xz', 'xy', or 'yz'); if not
            %  passed, 'xz' will be used
            %
            % Returns:
            %  obj: an array object
            %
            % Notes:
            %  : obj = ARRAY() Creates an empty array object.
            %
            %  : obj = ARRAY(N) Creates an array object where N array
            %  elements are uniformly spaced one-half wavelength apart 
            %  along the x-axis.
            %
            %  : obj = ARRAY(N,M) Creates an array object representing a 
            %  uniform planar array comprised of N rows of M elements,
            %  uniformly spaced one-half wavelength apart 
            %  in the x-z plane.
            if nargin < 1 % create empty array
                obj.reset();
            elseif nargin < 2 % create ULA
                obj.initialize_ula(N);
            elseif nargin < 3
                if ischar(M) % create ULA along specific axis
                    ax = M;
                    obj.initialize_ula(N,ax);
                else % create UPA
                    obj.initialize_upa(N,M);
                end
            else
                obj.initialize_upa(N,M,plane);
            end
        end
        
        % -----------------------------------------------------------------
        % Setup functions.
        % -----------------------------------------------------------------
        
        function reset(obj)
            % RESET Removes all array elements from the array.
            %
            % Usage:
            %  RESET()
            obj.x = [];
            obj.y = [];
            obj.z = [];
            obj.weights = [];
            obj.num_antennas = 0;
            obj.set_marker('kx');
        end
        
        function initialize_ula(obj,N,ax)
            % INITIALIZE_ULA Resets the array and creates a half-wavelength
            % spaced, uniform linear array along a desired axis.
            %
            % Usage:
            %  INITIALIZE_ULA(N)
            %  INITIALIZE_ULA(N,ax)
            %
            % Args:
            %  N: the number of array elements in the array
            %  ax: (optional) a string specifying which axis to create the
            %  ULA along (either 'x', 'y', or 'z'); if not passed, 'x' will
            %  be used
            if nargin < 3
                ax = 'x';
            end
            obj.reset();
            n = (0:N-1)/2;
            xx = zeros(1,N);
            yy = zeros(1,N);
            zz = zeros(1,N);
            if strcmpi(ax,'x')
                xx = n;
            elseif strcmpi(ax,'y')
                yy = n;
            elseif strcmpi(ax,'z')
                zz = n;
            else
                error('Invalid axis specifier (x, y, or z). Cannot create ULA.');
            end
            obj.add_element(xx,yy,zz);
            obj.translate(); % center at origin
        end
        
        function initialize_upa(obj,nrows,ncols,plane)
            % INITIALIZE_UPA Resets the array and creates a half-wavelength
            % spaced, uniform planar array in a desired plane.
            %
            % Usage:
            %  INITIALIZE_UPA(nrows)
            %  INITIALIZE_UPA(nrows,ncols)
            %  INITIALIZE_UPA(nrows,[],plane)
            %  INITIALIZE_UPA(nrows,ncols,plane)
            %
            % Args:
            %  nrows: number of rows (second axis) in the planar array
            %  ncols: (optional) number of columns (first axis) in the 
            %  planar array; if not passed, the number of rows (nrows) will
            %  be used
            %  plane: (optional) a string specifying which plane to create
            %  the UPA in (either 'xy', 'xz', or 'yz'); if not passed, 'xz'
            %  will be used
            if nargin < 3 || isempty(ncols)
                ncols = nrows;
            end 
            if nargin < 4 || isempty(plane)
                plane = 'xz';
            end
            obj.reset();
            m = (0:nrows-1)./2;
            n = (0:ncols-1)./2;
            N = nrows * ncols;
            if strcmpi(plane,'xz')
                xx = repelem(n,nrows);
                yy = zeros(1,N);
                zz = repmat(m,1,ncols);
            elseif strcmpi(plane,'xy')
                xx = repelem(n,nrows);
                yy = repmat(m,1,ncols);
                zz = zeros(1,N);
            elseif strcmpi(plane,'yz')
                xx = zeros(1,N);
                yy = repelem(n,nrows);
                zz = repmat(m,1,ncols);
            else
                error('Invalid axis specifier (x, y, or z). Cannot create ULA.');
            end
            obj.add_element(xx,yy,zz);
            obj.translate(); % center at origin
        end
        
        % -----------------------------------------------------------------
        % Set functions.
        % -----------------------------------------------------------------
        
        function set_marker(obj,marker)
            % SET_MARKER Sets the marker used when plotting the array 
            % elements.
            %
            % Usage:
            %  SET_MARKER()
            %  SET_MARKER(marker)
            %
            % Args:
            %  marker: (optional) a string specifying the plot marker to 
            %  use; in addition to MATLAB's plot markers (e.g., 'kx'), 
            %  'transmit' or 'receive' are also valid; if not passed, 'kx'
            %  is used
            if strcmpi(marker,'transmit')
                marker = 'bx'; % blue x for transmit arrays
            elseif strcmpi(marker,'receive')
                marker = 'r+'; % red + for receive arrays
            end
            obj.marker = marker;
        end
        
        function set_weights(obj,w)
            % SET_WEIGHTS Applies complex weights to each array element.
            % Note that these weights are applied directly and not
            % conjugated beforehand.
            %
            % Usage:
            %  SET_WEIGHTS()
            %  SET_WEIGHTS(w)
            % 
            % Args:
            %  w: (optional) a weight vector where the i-th array element 
            %  is weighted by the i-th element in w; if not passed, a
            %  vector of ones is used
            if nargin < 2 || isempty(w)
                w = ones(obj.num_antennas,1);
            end
            w = w(:); % force column vector
            if isequal(length(w),obj.num_antennas)
                obj.weights = w;
            else
                warning('Number of weights should equal number of array elements.');
                warning('Not setting array weights.');
            end
        end
        
        % -----------------------------------------------------------------
        % Modifying functions.
        % -----------------------------------------------------------------
        
        function add_element(obj,x,y,z)
            % ADD_ELEMENT Adds an element or group of elements to the array
            % based on their (x,y,z)-coordinates (in wavelengths).
            % 
            % Usage:
            %  ADD_ELEMENT(x,y,z)
            % 
            % Args:
            %  x: a scalar or vector of scalars of element x-coordinate(s)
            %  y: a scalar or vector of scalars of element y-coordinate(s)
            %  z: a scalar or vector of scalars of element z-coordinate(s)
            %
            % Notes:
            %  : If x, y, and z are not of equal length, an error is thrown.
            if isequal(length(x),length(y)) && isequal(length(x),length(z))
                obj.x = [obj.x x(:).'];
                obj.y = [obj.y y(:).'];
                obj.z = [obj.z z(:).'];
                obj.num_antennas = length(obj.x);
                obj.weights = ones(obj.num_antennas,1);
            else
                error('x, y, and z must be the same length.');
            end
        end
        
        function remove_element(obj,idx)
            % REMOVE_ELEMENT Removes an element from the array.
            %
            % Usage:
            %  REMOVE_ELEMENT()
            %  REMOVE_ELEMENT(idx)
            % 
            % Args:
            %  idx: (optional) index of the element to remove from the 
            %  array; if not passed, the last element will be removed
            if nargin < 2 || isempty(idx)
                idx = obj.num_antennas;
            else
                if idx > obj.num_antennas
                    error('Element index must be less than or equal to the number of elements in the array.');
                elseif idx < 1
                    error('Element index must be at least 1.');
                end
            end
            obj.x = [obj.x(1:idx-1) obj.x(idx+1:end)];
            obj.y = [obj.y(1:idx-1) obj.y(idx+1:end)];
            obj.z = [obj.z(1:idx-1) obj.z(idx+1:end)];
            obj.num_antennas = obj.num_antennas - 1;
        end
        
        function translate(obj,x,y,z)
            % TRANSLATE Shifts the location of all elements in the 
            % array by some change in the x, y, and z directions (in 
            % wavelengths). When x, y, and z are not passed, the array will
            % be centered at the origin.
            %
            % Usage:
            %  TRANSLATE()
            %  TRANSLATE(x)
            %  TRANSLATE(x,y)
            %  TRANSLATE(x,y,z)
            %
            % Args:
            %  x: (optional) wavelengths to move in the x direction; if not 
            %  passed, the negative mean x coordinate is used which will
            %  center the array in the x direction
            %  y: (optional) wavelengths to move in the y direction; if not 
            %  passed, the negative mean y coordinate is used which will
            %  center the array in the y direction
            %  z: (optional) wavelengths to move in the z direction; if not 
            %  passed, the negative mean z coordinate is used which will
            %  center the array in the z direction
            if nargin < 2 || isempty(x)
                x = -mean(obj.x);
            end
            if nargin < 3 || isempty(y)
                y = -mean(obj.y);
            end
            if nargin < 4 || isempty(z)
                z = -mean(obj.z);
            end
            obj.x = obj.x + x;
            obj.y = obj.y + y;
            obj.z = obj.z + z;
        end
        
        function rotate(obj,rot_x,rot_y,rot_z,inplace)
            % ROTATE Rotates the array in 3-D space along the x-, y-,
            % and z-axes by some specified rotations (in radians).
            %
            % Usage:
            %  ROTATE(rot_x)
            %  ROTATE(rot_x,rot_y)
            %  ROTATE(rot_x,rot_y,rot_z)
            %  ROTATE(rot_x,rot_y,rot_z,inplace)
            %
            % Args:
            %  rot_x: rotation around x-axis (radians)
            %  rot_y: (optional) rotation around y-axis (radians); if not
            %  passed, 0 is used
            %  rot_z: (optional) rotation around z-axis (radians); if not
            %  passed, 0 is used
            %  inplace: (optional) a boolean indicating if the rotation
            %  should made about the true origin (0,0,0) (false) or the
            %  array's center (true); if not passed, false is used
            if isempty(rot_x)
                rot_x = 0;
            end
            if nargin < 3 || isempty(rot_y)
                rot_y = 0;
            end
            if nargin < 4 || isempty(rot_z)
                rot_z = 0;
            end
            if nargin < 5 || isempty(inplace)
                inplace = false;
            end
            if inplace
                x_mean = mean(obj.x);
                y_mean = mean(obj.y);
                z_mean = mean(obj.z);
                obj.translate(); % shift to origin
            end
            for i = 1:obj.num_antennas
                x = obj.x(i);
                y = obj.y(i);
                z = obj.z(i);
                [u,v,w] = rotate_cartesian_point(x,y,z,rot_x,rot_y,rot_z);
                obj.x(i) = u;
                obj.y(i) = v;
                obj.z(i) = w;
            end
            if inplace
                obj.translate(x_mean,y_mean,z_mean); % shift back
            end
        end
        
        % -----------------------------------------------------------------
        % Get functions.
        % -----------------------------------------------------------------
        
        function a = get_array_response(obj,az,el)
            % GET_ARRAY_RESPONSE Returns the array response vector at a
            % given azimuth and elevation. This response is simply the
            % phase shifts experienced by the elements on an incoming plane
            % wave at a given azimuth and elevation, normalized to the 
            % first element in the array.
            %
            % Usage:
            %  a = GET_ARRAY_RESPONSE()
            %  a = GET_ARRAY_RESPONSE(az)
            %  a = GET_ARRAY_RESPONSE([],el)
            %  a = GET_ARRAY_RESPONSE(az,el)
            %
            % Args:
            %  az: (optional) azimuth angle of interest (radians); if not
            %  passed, 0 is used
            %  el: (optional) elevation angle of interest (radians); if not
            %  passed, 0 is used
            %
            % Returns:
            %  a: the array response vector at the azimuth and elevation of 
            %  interest
            if nargin < 2 || isempty(az)
                az = 0;
            end
            if nargin < 3 || isempty(el)
                el = 0;
            end
            dx = obj.x.' - obj.x(1); % distances relative to first element
            dy = obj.y.' - obj.y(1); % distances relative to first element
            dz = obj.z.' - obj.z(1); % distances relative to first element
            az = az(:).'; % row vector
            el = el(:).'; % row vector
            a = exp(1j.*2*pi*(dx.*sin(az).*cos(el) + dy.*cos(az).*cos(el) + dz.*sin(el)));
        end
        
        function g = get_array_gain(obj,az,el)
            % GET_ARRAY_GAIN Returns the array gain in a given direction 
            % (azimuth and elevation) with the current array weights 
            % applied.
            %
            % Usage:
            %  gain = GET_ARRAY_GAIN()
            %  gain = GET_ARRAY_GAIN(az)
            %  gain = GET_ARRAY_GAIN([],el)
            %  gain = GET_ARRAY_GAIN(az,el)
            %
            % Args:
            %  az: (optional) azimuth angle of interest (radians); if not
            %  passed, 0 is used
            %  el: (optional) elevation angle of interest (radians); if not
            %  passed, 0 is used
            %
            % Returns:
            %  g: complex gain of the weighted array in the azimuth and 
            %  elevation of interest
            if nargin < 2 || isempty(az)
                az = 0;
            end
            if nargin < 3 || isempty(el)
                el = 0;
            end
            a = obj.get_array_response(az,el);
            w = obj.weights;
            g = w.' * a;
        end
        
        function D = get_largest_dimension(obj)
            X = obj.x - obj.x.';
            Y = obj.y - obj.y.';
            Z = obj.z - obj.z.';
            R = sqrt(X.^2 + Y.^2 + Z.^2);
            D = max(R(:));
        end
        
        function a = get_weighted_array_response(obj,az,el)
            % GET_WEIGHTED_ARRAY_RESPONSE Returns the weighted array 
            % response vector at a given azimuth and elevation. 
            %
            % Usage:
            %  a = GET_WEIGHTED_ARRAY_RESPONSE()
            %  a = GET_WEIGHTED_ARRAY_RESPONSE(az)
            %  a = GET_WEIGHTED_ARRAY_RESPONSE([],el)
            %  a = GET_WEIGHTED_ARRAY_RESPONSE(az,el)
            %
            % Args:
            %  az: (optional) azimuth angle of interest (radians); if not
            %  passed, 0 is used
            %  el: (optional) elevation angle of interest (radians); if not
            %  passed, 0 is used
            %
            % Returns:
            %  a: the array response vector at the azimuth and elevation of 
            %  interest, incorporating array weights
            if nargin < 2
                az = [];
            end
            if nargin < 3
                el = [];
            end
            v = obj.get_array_response(az,el);
            w = obj.weights;
            a = v .* w;
        end
        
        function w = get_conjugate_beamformer(obj,az,el)
            % GET_CONJUGATE_BEAMFORMER Returns the conjugate beamforming 
            % weights for steering in particular azimuth and elevation 
            % directions.
            %
            % Usage:
            %  w = GET_CONJUGATE_BEAMFORMER()
            %  w = GET_CONJUGATE_BEAMFORMER(az)
            %  w = GET_CONJUGATE_BEAMFORMER([],el)
            %  w = GET_CONJUGATE_BEAMFORMER(az,el)
            %
            % Args:
            %  az: (optional) azimuth angle of interest (radians); if not
            %  passed, 0 is used
            %  el: (optional) elevation angle of interest (radians); if not
            %  passed, 0 is used
            %
            % Returns:
            %  w: array weights corresponding to the conjugate beamformer 
            %  that steers toward the azimuth and elevation of interest
            if nargin < 2 || isempty(az)
                az = 0;
            end
            if nargin < 3 || isempty(el)
                el = 0;
            end
            a = obj.get_array_response(az,el);
            w = conj(a);
        end

        function [x,az,el] = get_array_pattern_azimuth(obj,el,N,full)
            % GET_ARRAY_PATTERN_AZIMUTH Returns the weighted array pattern
            % as a function of azimuth angle for some fixed elevation 
            % angle.
            %
            % Usage:
            %  [x,az] = GET_ARRAY_PATTERN_AZIMUTH()
            %  [x,az] = GET_ARRAY_PATTERN_AZIMUTH(el)
            %  [x,az] = GET_ARRAY_PATTERN_AZIMUTH(el,N)
            %  [x,az] = GET_ARRAY_PATTERN_AZIMUTH(el,N,full)
            %
            % Args:
            %  el: (optional) elevation angle to use when evaluating the 
            %  azimuth array pattern (radians); if not passed, 0 is used
            %  N: (optional) number of azimuth points used to evaluate 
            %  array pattern; if not passed, 1024 is used
            %  full: (optional) a boolean specifying if the full azimuth
            %  sweep should be executed (true) or half (false); default is
            %  false; a full azimuth sweep is from [-pi,+pi); a half
            %  azimuth sweep is from [-pi/2,+pi/2)
            %
            % Returns:
            %  x: weighted array pattern as a function of azimuth angle
            %  az: azimuth angles (radians) used to assess the array
            %  pattern
            if nargin < 2 || isempty(el)
                el = 0;
            end
            if nargin < 3 || isempty(N)
                N = 1024;
            end
            if nargin < 4 || isempty(full)
                full = false;
            end
            if full
                th_start = -pi;
                th_stop = pi;
            else
                th_start = -pi/2;
                th_stop = pi/2;
            end
            th_step = (th_stop - th_start) / N;
            az = th_start:th_step:(th_stop-th_step);
            x = zeros(N,1);
            for i = 1:N
                x(i) = obj.get_array_gain(az(i),el);
            end
        end
        
        function [x,el,az] = get_array_pattern_elevation(obj,az,N,full)
            % GET_ARRAY_PATTERN_ELEVATION Returns the weighted array
            % pattern as a function of elevation angle for some fixed 
            % azimuth angle.
            %
            % Usage:
            %  [x,el] = GET_ARRAY_PATTERN_ELEVATION()
            %  [x,el] = GET_ARRAY_PATTERN_ELEVATION(az)
            %  [x,el] = GET_ARRAY_PATTERN_ELEVATION(az,N)
            %  [x,el] = GET_ARRAY_PATTERN_ELEVATION(az,N,full)
            %
            % Args:
            %  az: (optional) azimuth angle to use when evaluating the
            %  elevation array pattern (radians); if not passed, 0 is used
            %  N: (optional) number of elevation points used to evaluate 
            %  array pattern; if not passed, 1024 is used
            %  full: (optional) a boolean specifying if the full elevation
            %  sweep should be executed (true) or half (false); default is
            %  false; a full elevation sweep is from [-pi,+pi); a half
            %  elevation sweep is from [-pi/2,+pi/2)
            %
            % Returns:
            %  x: weighted array pattern as a function of elevation angle
            %  el: elevation angles (radians) used to assess the array
            %  pattern
            if nargin < 2 || isempty(az)
                az = 0;
            end
            if nargin < 3 || isempty(N)
                N = 1024;
            end
            if nargin < 4 || isempty(full)
                full = false;
            end
            if full
                th_start = -pi;
                th_stop = pi;
            else
                th_start = -pi/2;
                th_stop = pi/2;
            end
            th_step = (th_stop - th_start) / N;
            el = th_start:th_step:(th_stop-th_step);
            x = zeros(N,1);
            for i = 1:N
                x(i) = obj.get_array_gain(az,el(i));
            end
        end
        
        function xyz = get_array_center(obj)
            % GET_ARRAY_CENTER Returns the center of the array (in
            % wavelengths); particularly useful for an array that has been
            % translated/rotated.
            %
            % Usage:
            %  xyz = GET_ARRAY_CENTER()
            %
            % Returns:
            %  xyz: the center of the array in wavelengths
            mean_x = mean(obj.x);
            mean_y = mean(obj.y);
            mean_z = mean(obj.z);
            xyz = [mean_x; mean_y; mean_z];
        end
        
        % -----------------------------------------------------------------
        % Show functions.
        % -----------------------------------------------------------------
        
        function show_beamformer_pattern(obj,w)
            % SHOW_BEAMFORMER_PATTERN Plots the resulting beam pattern when
            % the array employs a specific set of beamforming weights. The
            % array weights are not overwritten.
            % 
            % Usage:
            %  SHOW_BEAMFORMER_PATTERN(w)
            % 
            % Args:
            %  w: a vector of complex beamforming weights
            w = w(:);
            orig_weights = obj.weights;
            obj.set_weights(w);
            obj.show_array_pattern();
            obj.set_weights(orig_weights);
        end
        
        function show_array_pattern(obj,az,el,N,full,loglin)
            % SHOW_ARRAY_PATTERN Plots the array pattern as a function of
            % azimuth for a fixed elevation and as a function of elevation
            % for a fixed azimuth.
            %
            % Usage:
            %  SHOW_ARRAY_PATTERN()
            %  SHOW_ARRAY_PATTERN(az)
            %  SHOW_ARRAY_PATTERN(az,el)
            %  SHOW_ARRAY_PATTERN(az,el,N)
            %  SHOW_ARRAY_PATTERN(az,el,N,full)
            %  SHOW_ARRAY_PATTERN(az,el,N,full,loglin)
            %
            % Args:
            %  az: (optional) the azimuth angle (in radians) to use when
            %  evaluating the array elevation pattern; if not passed, the
            %  default is used
            %  el: (optional) the elevation angle (in radians) to use when
            %  evaluating the array azimuth pattern; if not passed, the
            %  default is used
            %  N: (optional) number of points to take when evaluating the
            %  array pattern; if not passed, the default is used
            %  full: (optional) a boolean specifying if the full 
            %  sweep should be executed (true) or half (false); default is
            %  false; a full sweep is from [-pi,+pi); a half
            %  sweep is from [-pi/2,+pi/2)
            %  loglin: (optional) a string specifying if the magnitude
            %  should be in dB ('dB') or linear ('lin'); if not passed,
            %  dB is used
            if nargin < 2
                az = [];
            end
            if nargin < 3
                el = [];
            end
            if nargin < 4
                N = [];
            end
            if nargin < 5
                full = [];
            end
            if nargin < 6
                loglin = 'dB';
            end
            [xx,th,el] = obj.get_array_pattern_azimuth(el,N,full);
            if strcmpi(loglin,'dB')
                x = 20*log10(abs(xx));
                maglabel = 'Magnitude (dB)';
            else
                x = abs(xx);
                maglabel = 'Linear Magnitude';
            end
            figure();
            subplot(221);
            plot(th/pi*180,x,'-k'); grid on;
            xlabel('Azimuth (deg.)');
            ylabel(maglabel);
            title(['Elevation of ' num2str(el*180/pi) ' deg.']);
            subplot(223);
            plot(th/pi*180,angle(xx),'-k'); grid on;
            xlabel('Azimuth (deg.)');
            ylabel('Phase (rad.)');
            [xx,ph,az] = obj.get_array_pattern_elevation(az,N,full);
            if strcmpi(loglin,'dB')
                x = 20*log10(abs(xx));
            else
                x = abs(xx);
            end
            subplot(222);
            plot(ph/pi*180,x,'-k'); grid on;
            xlabel('Elevation (deg.)');
            ylabel(maglabel);
            title(['Azimuth of ' num2str(az*180/pi) ' deg.']);
            subplot(224);
            plot(ph/pi*180,angle(xx),'-k'); grid on;
            xlabel('Elevation (deg.)');
            ylabel('Phase (rad.)');
        end
        
        function show_array_pattern_azimuth(obj,ax,el,N,full)
            % SHOW_ARRAY_PATTERN_AZIMUTH Plots the magnitude of the 
            % array pattern as a function of azimuth angle.
            %
            % Usage:
            %  SHOW_ARRAY_PATTERN_AZIMUTH()
            %  SHOW_ARRAY_PATTERN_AZIMUTH(ax)
            %  SHOW_ARRAY_PATTERN_AZIMUTH(ax,el)
            %  SHOW_ARRAY_PATTERN_AZIMUTH(ax,el,N)
            %  SHOW_ARRAY_PATTERN_AZIMUTH(ax,el,N,full)
            %
            % Args:
            %  ax: (optional) an axes handle; if not passed, a new
            %  one will be created
            %  el: (optional) the elevation angle (in radians) to use when
            %  evaluating the array azimuth pattern; if not passed, the
            %  default is used
            %  N: (optional) number of points to take when evaluating the
            %  array pattern; if not passed, the default is used
            %  full: (optional) a boolean specifying if the full azimuth
            %  sweep should be executed (true) or half (false); default is
            %  false; a full azimuth sweep is from [-pi,+pi); a half
            %  azimuth sweep is from [-pi/2,+pi/2)
            if nargin < 2 || isempty(ax)
                figure();
                ax = axes();
            end
            if nargin < 3
                el = [];
            end
            if nargin < 4
                N = [];
            end
            if nargin < 5
                full = [];
            end
            [xx,th,el] = obj.get_array_pattern_azimuth(el,N,full);
            plot(ax,th*180/pi,abs(xx),'-k'); 
            grid(ax,'on');
            xlabel(ax,'Azimuth (deg.)');
            ylabel(ax,'Linear Magnitude');
            title(ax,['Elevation of ' num2str(el*180/pi) ' deg.']);
        end
        
        function show_array_pattern_elevation(obj,ax,az,N,full)
            % SHOW_ARRAY_PATTERN_ELEVATION Plots the magnitude of the 
            % array pattern as a function of elevation angle.
            %
            % Usage:
            %  SHOW_ARRAY_PATTERN_ELEVATION()
            %  SHOW_ARRAY_PATTERN_ELEVATION(ax)
            %  SHOW_ARRAY_PATTERN_ELEVATION(ax,az)
            %  SHOW_ARRAY_PATTERN_ELEVATION(ax,az,N)
            %  SHOW_ARRAY_PATTERN_ELEVATION(ax,az,N,full)
            %
            % Args:
            %  ax: (optional) an existing axes handle; if not passed, a new
            %  one will be created
            %  az: (optional) the azimuth angle (in radians) to use when
            %  evaluating the array elevation pattern; if not passed, the
            %  default is used
            %  N: (optional) number of points to take when evaluating the
            %  array pattern; if not passed, the default is used
            %  full: (optional) a boolean specifying if the full elevation
            %  sweep should be executed (true) or half (false); default is
            %  false; a full elevation sweep is from [-pi,+pi); a half
            %  elevation sweep is from [-pi/2,+pi/2)
            if nargin < 2 || isempty(ax)
                figure();
                ax = axes();
            end
            if nargin < 3
                az = [];
            end
            if nargin < 4
                N = [];
            end
            if nargin < 5
                full = [];
            end
            [xx,ph,az] = obj.get_array_pattern_elevation(az,N,full);
            plot(ax,ph*180/pi,abs(xx),'-k'); 
            grid(ax,'on');
            xlabel(ax,'Elevation (deg.)');
            ylabel(ax,'Linear Magnitude');
            title(ax,['Azimuth of ' num2str(az*180/pi) ' deg.']);
        end
        
        function show_polar_array_pattern_azimuth(obj,ax,el,N,full)
            % SHOW_POLAR_ARRAY_PATTERN_AZIMUTH Plots the azimuth array
            % pattern in a polar plot.
            %
            % Usage:
            %  SHOW_POLAR_ARRAY_PATTERN_AZIMUTH()
            %  SHOW_POLAR_ARRAY_PATTERN_AZIMUTH(ax)
            %  SHOW_POLAR_ARRAY_PATTERN_AZIMUTH(ax,el)
            %  SHOW_POLAR_ARRAY_PATTERN_AZIMUTH(ax,el,N)
            %  SHOW_POLAR_ARRAY_PATTERN_AZIMUTH(ax,el,N,full)
            % 
            % Args:
            %  ax: (optional) axes handle to plot on; if not provided, will
            %  create a new figure and axes to plot on
            %  el: (optional) the elevation angle (radians) to use when
            %  evaluating the azimuth pattern
            %  N: (optional) number of points to take when evaluating the
            %  array pattern; if not passed, the default is used
            %  full: (optional) a boolean specifying if the full
            %  sweep should be executed (true) or half (false); default is
            %  false; a full sweep is from [-pi,+pi); a half sweep is from
            %  [-pi/2,+pi/2)
            if nargin < 2 || isempty(ax)
                figure();
                ax = polaraxes();
            end
            if nargin < 3
                el = [];
            end
            if nargin < 4
                N = [];
            end
            if nargin < 5
                full = [];
            end
            [x,th,el] = obj.get_array_pattern_azimuth(el,N,full);
            polarplot(ax,th.',abs(x),'-k'); 
            thetalim(ax,[min(th)*180/pi max(th)*180/pi]);
            rlim(ax,[0 max(abs(x))]);
            ax.ThetaDir = 'clockwise';
            ax.ThetaZeroLocation = 'top';
            ax.RAxis.Label.String = 'Linear Magnitude';
            ticks = [-90:15:90];
            thetatickformat('${%g}^{\\circ}$');
            ax.ThetaTick = ticks;
            ax.ThetaLim = [min(ticks),max(ticks)];
            title(ax,['Elevation of ' num2str(el*180/pi) ' deg.']);
        end
        
        function show_polar_array_pattern_elevation(obj,ax,az,N,full)
            % SHOW_POLAR_ARRAY_PATTERN_ELEVATION Plots the elevation array
            % pattern in a polar plot.
            %
            % Usage:
            %  SHOW_POLAR_ARRAY_PATTERN_ELEVATION()
            %  SHOW_POLAR_ARRAY_PATTERN_ELEVATION(ax)
            %  SHOW_POLAR_ARRAY_PATTERN_ELEVATION(ax,az)
            %  SHOW_POLAR_ARRAY_PATTERN_ELEVATION(ax,az,N)
            %  SHOW_POLAR_ARRAY_PATTERN_ELEVATION(ax,az,N,full)
            % 
            % Args:
            %  ax: (optional) axes handle to plot on; if not provided, will
            %  create a new figure and axis to plot on
            %  az: (optional) the azimuth angle (radians) to use when
            %  evaluating the elevation pattern
            %  N: (optional) number of points to take when evaluating the
            %  array pattern; if not passed, the default is used
            %  full: (optional) a boolean specifying if the full
            %  sweep should be executed (true) or half (false); default is
            %  false; a full sweep is from [-pi,+pi); a half sweep is from
            %  [-pi/2,+pi/2)
            if nargin < 2 || isempty(ax)
                figure();
                ax = polaraxes();
            end
            if nargin < 3
                az = [];
            end
            if nargin < 4
                N = [];
            end
            if nargin < 5
                full = [];
            end
            [x,ph,az] = obj.get_array_pattern_elevation(az,N,full);
            polarplot(ax,ph.',abs(x),'-k');
            rlim(ax,[0 max(abs(x))]);
            thetalim(ax,[min(ph)*180/pi max(ph)*180/pi]);
            ax.ThetaDir = 'clockwise';
            ax.ThetaZeroLocation = 'top';
            ax.RAxis.Label.String = 'Linear Magnitude';
            title(ax,['Azimuth of ' num2str(az*180/pi) ' deg.']);
        end
        
        function show_radiation_pattern(obj,ax,res,full)
            % SHOW_RADIATION_PATTERN Plots the array gain in a 3-D plot.
            %
            % Usage:
            %  SHOW_RADIATION_PATTERN()
            %  SHOW_RADIATION_PATTERN(ax)
            %  SHOW_RADIATION_PATTERN(ax,res)
            %  SHOW_RADIATION_PATTERN(ax,res,full)
            %  SHOW_RADIATION_PATTERN([],res)
            %  SHOW_RADIATION_PATTERN([],res,full)
            %  SHOW_RADIATION_PATTERN([],[],full)
            %  SHOW_RADIATION_PATTERN(ax,[],full)
            % 
            % Args:
            %  ax: (optional) axes handle to plot on; if not provided, will
            %      create a new figure and axis to plot on
            %  az: (optional) a string specifying the resolution of the
            %      plot ('low', 'medium', 'high', or 'best'); default is 
            %      'medium'
            %  full: (optional) a boolean specifying if the full
            %        sweep should be executed (true) or half (false); 
            %        default is false; a full sweep is from [-pi,+pi); a 
            %        half sweep is from [-pi/2,+pi/2)
            if nargin < 2 || isempty(ax)
                figure();
                ax = axes();
            end
            if nargin < 3 || isempty(res)
                res = 'med';
            end
            if strcmpi(res,'low') || strcmpi(res,'lo')
                num_az = 180;
                num_el = 90;
            elseif strcmpi(res,'medium') || strcmpi(res,'med')
                num_az = 360;
                num_el = 180;
            elseif strcmpi(res,'high') || strcmpi(res,'hi')
                num_az = 720;
                num_el = 360;
            elseif strcmpi(res,'best') || strcmpi(res,'max')
                num_az = 1440;
                num_el = 720;
            else
                error('Invalid resolution specifier. Choices are: low, medium, or high.');
            end
            if nargin < 4 || isempty(full)
                full = false;
            else
                full = logical(full);
            end
            if full
                lower_az = -pi;
                upper_az = pi;
            else
                lower_az = -pi/2;
                upper_az = pi/2;
            end
            AoA_ele_rad = linspace(-pi/2,pi/2,num_el);
            AoA_azi_rad = linspace(lower_az,upper_az,num_az);
            AoA_ele_rad_list = AoA_ele_rad(:);
            AoA_azi_rad_list = AoA_azi_rad(:);
            G = zeros(num_az,num_el);
            for idx_el = 1:num_el
                v = obj.get_array_gain(AoA_azi_rad_list,AoA_ele_rad_list(idx_el)).';
                G(:,idx_el) = abs(v).^2;
            end
            [AoA_ele_rad,AoA_azi_rad] = meshgrid(AoA_ele_rad,AoA_azi_rad);
            [x,y,z] = sph2cart(AoA_azi_rad,AoA_ele_rad,G);
            surf(ax,x,y,z,sqrt(x.^2+y.^2+z.^2));
            xlabel(ax,'$y$');
            ylabel(ax,'$x$');
            zlabel(ax,'$z$');
            axis equal;
            shading interp;
        end
        
        function show_codebook_radiation_pattern(obj,F)
            % SHOW_CODEBOOK_RADIATION_PATTERN Plots the array gain in a 
            % 3-D plot for each beam in a codebook.
            %
            % Usage:
            %  SHOW_CODEBOOK_RADIATION_PATTERN(F)
            % 
            % Args:
            %  F: a matrix where each column is a vetor of beamforming
            %  weights
            figure();
            ax = axes();
            num_beams = length(F(1,:));
            for idx = 1:num_beams
                obj.set_weights(F(:,idx));
                obj.show_radiation_pattern(ax,'medium',false);
                hold(ax,'on');
            end
            hold(ax,'off');
        end
        
        function [fig,ax] = show_2d(obj,ax,plane)
            % SHOW_2D Plots the array elements in 2-D space.
            % 
            % Usage:
            %  [fig,ax] = SHOW2D()
            %  [fig,ax] = SHOW2D(ax)
            %  [fig,ax] = SHOW2D(ax,plane)
            %  [fig,ax] = SHOW2D([],plane)
            %
            % Args:
            %  ax: (optional) an axes handle to plot on
            %  plane: (optional) a string specifying which plane to show
            %  (either 'xy', 'xz', or 'yz'); if not passed, 'xz' is used.
            %
            % Returns:
            %  fig: a figure handle
            %  ax: an axes handle
            if nargin < 2 || isempty(ax)
                fig = figure();
                ax = axes();
            end
            if nargin < 3 || isempty(plane)
                plane = 'xz';
            end
            if strcmpi(plane,'xy')
                xx = obj.x;
                yy = obj.y;
            elseif strcmpi(plane,'xz')
                xx = obj.x;
                yy = obj.z;
            elseif strcmpi(plane,'yz')
                xx = obj.y;
                yy = obj.z;
            else
                error('Invalid plane specifier.');
            end
            plot(ax,xx,yy,obj.marker); 
            hold(ax,'off');
            grid(ax,'on');
            xlabel(ax,['$' plane(1) '$ (in $\lambda$)']);
            ylabel(ax,['$' plane(2) '$ (in $\lambda$)']);
            fig = gcf();
        end
        
        function [fig,ax] = show_3d(obj,ax)
            % SHOW_3D Plots the array elements in 3-D space.
            % 
            % Usage:
            %  [fig,ax] = SHOW3D()
            %  [fig,ax] = SHOW3D(ax)
            %
            % Args:
            %  ax: (optional) existing axes to plot on
            % 
            % Returns:
            %  fig: a figure handle
            %  ax: an axes handle
            if nargin < 2 || isempty(ax)
                fig = figure();
                ax = axes();
            end
            scatter3(ax,obj.x,obj.y,obj.z,obj.marker);
            hold(ax,'off');
            grid(ax,'on');
            xlabel(ax,'$x$ (in $\lambda$)');
            ylabel(ax,'$y$ (in $\lambda$)');
            zlabel(ax,'$z$ (in $\lambda$)');
            fig = gcf();
        end
        
    end
end