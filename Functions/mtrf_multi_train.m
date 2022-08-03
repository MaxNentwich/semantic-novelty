function model = mtrf_multi_train(stim, resp, lambda, sparse_compute)
%mTRFtrain mTRF Toolbox training function.
%   MODEL = MTRFTRAIN(STIM,RESP,FS,MAP,TMIN,TMAX,LAMBDA) performs ridge
%   regression on the stimulus property STIM and the neural response data
%   RESP to solve for their linear mapping function MODEL. Pass in MAP==1
%   to map in the forward direction or MAP==-1 to map backwards. The
%   sampling frequency FS should be defined in Hertz and the time lags
%   should be set in milliseconds between TMIN and TMAX. Regularisation is
%   controlled by the ridge parameter LAMBDA.
%
%   [...,T,C] = MTRFTRAIN(...) also returns the vector of time lags T for
%   plotting MODEL and the regression constant C for absorbing any bias
%   when testing MODEL.
%
%   Inputs:
%   stim   - stimulus property (time by lag)
%   resp   - neural response data (time by channels)
%   fs     - sampling frequency (Hz)
%   tmin   - minimum time lag (ms)
%   tmax   - maximum time lag (ms)
%   lambda - ridge parameter
%
%   Outputs:
%   model  - linear mapping function
%   c      - regression constant
%
%   See README for examples of use.
%
%   See also LAGGEN MTRFTRANSFORM MTRFPREDICT MTRFCROSSVAL
%   MTRFMULTICROSSVAL.

%   References:
%      [1] Lalor EC, Pearlmutter BA, Reilly RB, McDarby G, Foxe JJ (2006)
%          The VESPA: a method for the rapid estimation of a visual evoked
%          potential. NeuroImage 32:1549-1561.
%      [1] Crosse MC, Di Liberto GM, Bednar A, Lalor EC (2015) The
%          multivariate temporal response function (mTRF) toolbox: a MATLAB
%          toolbox for relating neural signals to continuous stimuli. Front
%          Hum Neurosci 10:604.

%   Author: Edmund Lalor, Michael Crosse, Giovanni Di Liberto
%   Lalor Lab, Trinity College Dublin, IRELAND
%   Email: edmundlalor@gmail.com
%   Website: www.lalorlab.net
%   April 2014; Last revision: Jan 8, 2016

% Edit 10/26/2020, Max, 
% Function was adapted to take a toplitz matrix as an input and compute the trf from there 

% Assign lag/toeplitz matrix and response
if sparse_compute
    X = sparse(stim);
else
    X = stim;
end
y = resp;

% Set up regularisation
dim = size(X,2);
M = eye(dim,dim);

scale = lambda * mean(eig(X'*X));

% Calculate model
model = (X'*X+scale*M)\(X'*y);

end