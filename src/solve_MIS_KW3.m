function [tvals,Y,nf,ns] = solve_MIS_KW3(fs,ff,tvals,Y0,hs,hf)
% usage: [tvals,Y,nf,ns] = solve_MIS_KW3(fs,ff,tvals,Y0,hs,hf)
%
% Fixed time step MIS-KW3, explicit+explicit multirate Runge-Kutta
% method for the vector-valued ODE problem
%     y' = fs(t,Y) + ff(t,Y), t >= t0, y in R^n,
%     Y0 = [y1(t0), y2(t0), ..., yn(t0)]'.
% The individual time steps are performed using the step_MIS.m
% function; this routine sets the inner and outer Butcher tables to
% the KW3 table, and calls step_MIS.m in a loop to fill the output
% arrays.
%
% Inputs:
%     fs     = function handle for (slow) ODE RHS
%     ff     = function handle for (fast) ODE RHS
%     tvals  = array of desired output times, [t0, t1, t2, ..., tN]
%     Y0     = solution vector at start of step (column vector of length n)
%     hs     = step size to use for slow time scale
%     hf     = desired step size to use for fast time scale,
%                  hf <= hs*min_{i}(co(i+1)-co(i))
%              Note: this is only a target step size; in fact we
%              will determine each substepping interval and find
%              hinner <= hi such that we take an integer number of
%              steps to subcycle up to each outer stage time.
%
% Outputs:
%     tvals  = the same as the input array tvals
%     Y      = [y(t0), y(t1), y(t2), ..., y(tN)], where each
%               y(t*) is a column vector of length n.
%     ns     = number of 'slow' right hand side calls
%     nf     = number of 'fast' right hand side calls
%
% Daniel R. Reynolds
% Department of Mathematics
% Southern Methodist University
% July 2018
% All Rights Reserved

% set KW3 Butcher table
B = butcher('Knoth-Wolke-ERK');

% initialize output arrays
N = length(tvals)-1;
n = length(Y0);
Y = zeros(n,N+1);
Y(:,1) = Y0;

% initialize diagnostics
ns = 0;
nf = 0;

% set the solver parameters
ONEMSM = 1-sqrt(eps);  % coefficient to account for floating-point roundoff

% initialize temporary variables
t = tvals(1);
Ynew = Y0;
Jf = @(t,y) 0;  % no Jacobian required for explicit+explicit methods

% iterate over output time steps
for tstep = 1:N

   % loop over internal time steps to get to desired output time
   while (t < tvals(tstep+1)*ONEMSM)

      % bound internal time step
      h = min([hs, tvals(tstep+1)-t]);   % stop at output times

      % call MIS stepper to do the work, increment counters
      [Ynew,m] = step_MIS(fs,ff,Jf,t,Ynew,B,B,h,hf);
      ns = ns + 3;
      nf = nf + 3*m;
      t  = t + h;

   end

   % store updated solution in output array
   Y(:,tstep+1) = Ynew;

end  % time output loop

% end function
