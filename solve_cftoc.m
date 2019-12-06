function [feas, zOpt, uOpt] = solve_cftoc(P, PN, Q, R, N, z0, zL, zU, uL, uU, bf, Af, safe_param, zgoal, ztar)

yalmip('clear')
% mpc paramter
nz = 4; nu = 2;
dt = 0.5;

z = sdpvar(nz,N+1);
u = sdpvar(nu,N);
ztar_pred = zeros(nz,N+1);
ztar_pred(:,1) = ztar; % match initial state with measurement state 
feas = false;

constr = [z(:,1) == z0];

% Terminal Constraint
if isempty(Af)
    constr = [constr z(:,N+1)==bf];
else
    constr = [constr Af*z(:,N+1)<=bf];
end

% 
cost = z(1,N+1)*PN*z(1,N+1); 

for k = 1:N
    % cost at each time step
    cost = cost + (z(1,k)-zgoal)*Q*(z(1,k)-zgoal) + z(4,k)*P*z(4,k) + u(:,k).'*R*u(:,k); 
    % constraint at each time step
    constr = constr + [uL <= u(:,k), u(:,k) <= uU, zL <= z(:,k), z(:,k)<=zU];
    % state equation (transition)
    constr = constr + [z(:,k+1) == ego_vehicle(z(:,k),u(:,k))];
    % time-varying constraint for safety --> using safe_param (d_safe;eps)
    gap = ztar_pred(1:2,k)-z(1:2,k);
%     constr = constr + [gap(1)^2+gap(2)^2 >= safe_param(1)];
    % prediction of ztar in the loop of mpc
    ztar_pred(2,k+1) = ztar_pred(2,k) + ztar(3)*dt; 
end
% constr = constr + [ztar_pred(2,end)<=z(2,end)-safe_param(2)]; 

options = sdpsettings('verbose',0,'solver','fmincon');
sol = optimize(constr,cost,options);

if sol.problem == 0
    feas = true;
else
    zOpt = [];
    uOpt = [];
    disp(sol.problem)
    return;
end

zOpt = double(z);
uOpt = double(u);
end
