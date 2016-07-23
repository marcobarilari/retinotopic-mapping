function sim = scaleif(im, varargin)%  function sim = scaleif(im, newMin, newMax, oldMin, oldMax)%  Scales an image such that its lowest value attains newMin and%  it�s highest value attains newMax.  OldMin and oldMax are not%  necessary but are useful when you don't want to use the true%  min or max value.%% Adapted by Ione Fine, based on code from Rick Anthony% 6/5/2000length(varargin);if length(varargin)==0    newMin=0;    newMax=1;    oldMin = min(im(:));    oldMax = max(im(:));elseif length(varargin)==2    newMin=varargin{1};    newMax=varargin{2};    oldMin = min(im(:));     oldMax = max(im(:));elseif length(varargin)==4    newMin=varargin{1};    newMax=varargin{2};    oldMin=varargin{3};    oldMax=varargin{4};else     disp('Wrong number of input arguments');    sim=NaN;    returnendif (newMin>=newMax)    disp('Sorry new min must be smaller than new max');    sim=NaN;    returnendif (oldMin>=oldMax)    disp('Sorry old min must be smaller than old max');    sim=NaN;    returnenddelta = (newMax-newMin)/(oldMax-oldMin);sim = delta*(im-oldMin) + newMin;