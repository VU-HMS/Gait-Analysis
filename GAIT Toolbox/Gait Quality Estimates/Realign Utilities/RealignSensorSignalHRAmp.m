function [RealignedAcc,RotationMatrixT,Flags] = RealignSensorSignalHRAmp(Acc, FS, plotje)
%% function [RealignedAcc,RotationMatrixT,Flags] = RealignSensorSignalHRAmp(Acc, FS, plotje)
% Apply realignment as described in Rispens S, Pijnappels M, van Schooten K, Beek PJ, 
% Daffertshofer A, van Die�n JH (2014). Consistency of gait characteristics as determined 
% from acceleration data collected at different trunk locations. Gait Posture 2014;40(1):187-92.

%% History
% 2013/05/31 SR solve problem of ML-AP rotation of appr. 90 degrees ("Maximum number of function evaluations has been exceeded") 
% 2013/08/15 SR use literature HR (i.e. amplitude not power, and harmonic frequencies not sin^4 windows) 
% 2013/08/16 SR correct: use abs(X) instead of sqrt(X.*X)
% 2013/09/11 SR use only relevant F (containing odd or even harmonics) and speed up determination of harmonic frequencies 

%% Define VT direction (RVT) as direction of mean acceleration
MeanAcc = mean(Acc);
RVT = MeanAcc'/norm(MeanAcc);
RMLGuess = cross([0;0;1],RVT); RMLGuess = RMLGuess/norm(RMLGuess);
RAPGuess = cross(RVT,RMLGuess); RAPGuess = RAPGuess/norm(RAPGuess);

%% Estimate stride frequency
[StrideFrequency, ~] = StrideFrequencyFrom3dAcc(Acc, FS);
AccDetrend = detrend(Acc,'constant');
N = size(AccDetrend,1);

%% calculate complex DFT
F = FS*(0:(N-1))'/N;

dF = FS/N;
FHarmRange = [(1:20)'-0.1, (1:20)'+0.1]*StrideFrequency;

EvenRanges = FHarmRange(2:2:end,:);
OddRanges = FHarmRange(1:2:end,:);

EvenHarmonics = zeros(size(F));
for j=1:size(EvenRanges,1)
    IXRange = [EvenRanges(j,1)/dF, EvenRanges(j,2)/dF]+1;
    IXRangeRound = min(N,round(IXRange));
    EvenHarmonics(IXRangeRound(1):IXRangeRound(2)) = EvenHarmonics(IXRangeRound(1):IXRangeRound(2)) + 1;
    EvenHarmonics(IXRangeRound(1)) = EvenHarmonics(IXRangeRound(1)) - (IXRange(1)-IXRangeRound(1)+0.5);
    EvenHarmonics(IXRangeRound(2)) = EvenHarmonics(IXRangeRound(2)) - (IXRangeRound(2)-IXRange(2)+0.5);
end

OddHarmonics = zeros(size(F));
for j=1:size(OddRanges,1)
    IXRange = [OddRanges(j,1)/dF, OddRanges(j,2)/dF]+1;
    IXRangeRound = min(N,round(IXRange));
    OddHarmonics(IXRangeRound(1):IXRangeRound(2)) = OddHarmonics(IXRangeRound(1):IXRangeRound(2)) + 1;
    OddHarmonics(IXRangeRound(1)) = OddHarmonics(IXRangeRound(1)) - (IXRange(1)-IXRangeRound(1)+0.5);
    OddHarmonics(IXRangeRound(2)) = OddHarmonics(IXRangeRound(2)) - (IXRangeRound(2)-IXRange(2)+0.5);
end

%% select only frequencies that contain odd or even harmonics
RelevantF = OddHarmonics~=0 | EvenHarmonics~=0;
OddHarmonics = OddHarmonics(RelevantF);
EvenHarmonics = EvenHarmonics(RelevantF);
DFT = fft(AccDetrend,N,1);
DFT = DFT(RelevantF,:);
DFTMLG = DFT*RMLGuess;
DFTAPG = DFT*RAPGuess;

%% Initial estimation of ML-AP realignment (educated guess)
% We start of by finding the directions ML = MLguess + x*APguess for which 
% the 'harmonic ratio' for the ML directions is maximal or minimal, and we 
% do this by varying x in still the power variant of HR instead of amplitude:
 HRML = @(x) real(((OddHarmonics'.*(DFTMLG'+x*DFTAPG'))*(DFTMLG+x*DFTAPG))...
      /((EvenHarmonics'.*(DFTMLG'+x*DFTAPG'))*(DFTMLG+x*DFTAPG)));
% or by substititutions
a = real((OddHarmonics.*DFTAPG)'*DFTAPG);
b = real((OddHarmonics.*DFTMLG)'*DFTAPG + (OddHarmonics.*DFTAPG)'*DFTMLG);
c = real((OddHarmonics.*DFTMLG)'*DFTMLG);
d = real((EvenHarmonics.*DFTAPG)'*DFTAPG);
e = real((EvenHarmonics.*DFTMLG)'*DFTAPG + (EvenHarmonics.*DFTAPG)'*DFTMLG);
f = real((EvenHarmonics.*DFTMLG)'*DFTMLG);
% and by setting d/dx(HRML(x))==0 we get the quadratic formula
aq = a*e-b*d;
bq = 2*a*f-2*c*d;
cq = b*f-c*e;
% DT = bq^2-4*aq*cq = 4*(a*f-*c*d)*(a*f-c*d) - 4*(a*e-b*d)*(b*f-c*e)
%                   = 4aaff +4ccdd -8acdf -4abef -4bcde +4acee + 4bbdf 
%                   = 4aaff +4ccdd -4abef -4bcde +4ac(ee-df) +4(bb-ac)df 
x = (-bq +[1 -1]*sqrt(bq.^2-4*aq*cq))/(2*aq);
% with hopefully two solutions for x. 

% from here on use amplitude HR:
HRML = @(x) real((OddHarmonics'*abs(DFTMLG+x*DFTAPG))...
     /(EvenHarmonics'*abs(DFTMLG+x*DFTAPG)));
% now we take the x for which the HR is maximal, and the x rotated 90
% degrees fo which it is minimal, and take the mean angle between them
HR1 = HRML(x(1));
HR2 = HRML(x(2));
if HR1 > HR2
    thetas = atan([x(1),-1/x(2)]);
else
    thetas = atan([-1/x(1),x(2)]);
end
theta = mean(thetas);
xeg = tan(theta);
if abs(diff(thetas)) > pi/2 % thetas are more than 90 degrees apart, and the 'mean of the two axes' should be rotated 90 degrees 
    xeg = -1/xeg;
end

%% Numerical search for best harmonic ratios product
% Now we want to improve the solution, since the two above directions are 
% not necessarily orthogonal. Thus we want to find the orthogonal 
% directions ML = MLguess + x*APguess, and AP = APguess - x*MLguess, 
% for which the product of 'harmonic ratios' for the ML and AP directions 
% is maximal, and we do this by varying x, starting with the educated guess
% above using power instead of amplitude:
%   HRML = ((OddHarmonics'.*(DFTMLG'+x*DFTAPG'))*(DFTMLG+x*DFTAPG))...
%     /((EvenHarmonics'.*(DFTMLG'+x*DFTAPG'))*(DFTMLG+x*DFTAPG));
%   HRAP = ((EvenHarmonics'.*(-x*DFTMLG'+DFTAPG'))*(-x*DFTMLG+DFTAPG))...
%     /((OddHarmonics'.*(-x*DFTMLG'+DFTAPG'))*(-x*DFTMLG+DFTAPG));
% and
%   HR_Prod = HRML*HRAP = ...

% Now use amplitude
Minus_HR_Prod = @(x) -real(...
                (OddHarmonics'*abs(DFTMLG+x*DFTAPG))...
               /(EvenHarmonics'*abs(DFTMLG+x*DFTAPG))...
               *(EvenHarmonics'*abs(-x*DFTMLG+DFTAPG))...
               /(OddHarmonics'*abs(-x*DFTMLG+DFTAPG)));
options = optimset('Display','off');
[xopt1,Minus_HR_Prod_opt1,exitflag1]=fminsearch(Minus_HR_Prod,xeg, options);
if exitflag1 == 0 && abs(xopt1) > 100 % optimum for theta beyond +- pi/2
    [xopt1a,Minus_HR_Prod_opt1a,exitflag1a]=fminsearch(Minus_HR_Prod,-xopt1);
    if ~(exitflag1a == 0 && abs(xopt1a) > 100)
        % xopt1org = xopt1;
        xopt1 = xopt1a;
        Minus_HR_Prod_opt1 = Minus_HR_Prod_opt1a;
    end
end
options = optimset('LargeScale','off','GradObj','off','Display','notify');
[xopt2,Minus_HR_Prod_opt2,exitflag2]=fminunc(Minus_HR_Prod,xopt1,options);
if exitflag2 == 0 && abs(xopt2) > 100 % optimum for theta beyond +- pi/2
    [xopt2a,Minus_HR_Prod_opt2a,exitflag2a]=fminsearch(Minus_HR_Prod,-xopt2);
    if ~(exitflag2a == 0 && abs(xopt2a) > 100)
        xopt2 = xopt2a;
        Minus_HR_Prod_opt2 = Minus_HR_Prod_opt2a;
    end
end

RML = (RMLGuess+xopt2*RAPGuess)/sqrt(1+xopt2^2);
RAP = cross(RVT,RML); RAP = RAP/norm(RAP);

RT = [RVT,RML,RAP];
if nargout > 1
    RotationMatrixT = RT;
end
RealignedAcc = Acc*RT;
if nargout > 2
    Flags = [exitflag1,exitflag2];
end

if nargin > 2 && plotje
    Thetas = pi*(-0.49:0.01:0.49)';
    Xs = tan(Thetas);
    HR_Prod = nan(size(Xs));
    HRMLs = nan(size(Xs));
    for i=1:numel(Xs)
        HR_Prod(i,1) = -Minus_HR_Prod(Xs(i));
        HRMLs(i,1) = HRML(Xs(i));
    end
    figure(); 
    semilogy(Thetas,[HR_Prod,HRMLs.^2]);
    hold on;
    semilogy(atan(x),[HR1,HR2].^2,'r.');
    semilogy(atan([xopt1;xopt2]),-[Minus_HR_Prod_opt1;Minus_HR_Prod_opt2],'g.');
    semilogy(atan(xeg),-Minus_HR_Prod(xeg),'kx');
end

%% attempt to solve it analytically:
% % We can rewrite HR_Prod as:
% % HR_Prod = 
% %    ( (x.^2)*((OddHarmonics.*DFTAPG)'*DFTAPG) ...
% %     +  x*((OddHarmonics.*DFTMLG)'*DFTAPG + (OddHarmonics.*DFTAPG)'*DFTMLG)...
% %     +  ((OddHarmonics.*DFTMLG)'*DFTMLG) )...
% %  /
% %     ( (x.^2)*((EvenHarmonics.*DFTAPG)'*DFTAPG) ...
% %     +  x*((EvenHarmonics.*DFTMLG)'*DFTAPG + (EvenHarmonics.*DFTAPG)'*DFTMLG)...
% %     +  ((EvenHarmonics.*DFTMLG)'*DFTMLG) )
% %  *
% %    ( (x.^2)*((EvenHarmonics.*DFTMLG)'*DFTMLG) ...
% %     -  x*((EvenHarmonics.*DFTMLG)'*DFTAPG + (EvenHarmonics.*DFTAPG)'*DFTMLG)...
% %     +  ((EvenHarmonics.*DFTAPG)'*DFTAPG) )...
% %  /
% %     ( (x.^2)*((OddHarmonics.*DFTMLG)'*DFTMLG) ...
% %     -  x*((OddHarmonics.*DFTMLG)'*DFTAPG + (OddHarmonics.*DFTAPG)'*DFTMLG)...
% %     +  ((OddHarmonics.*DFTAPG)'*DFTAPG) )
% % 
% % or by making these substitutions:
% a2 = (OddHarmonics.*DFTAPG)'*DFTAPG;
% a1 = (OddHarmonics.*DFTMLG)'*DFTAPG + (OddHarmonics.*DFTAPG)'*DFTMLG;
% a0 = (OddHarmonics.*DFTMLG)'*DFTMLG;
% c2 = (EvenHarmonics.*DFTAPG)'*DFTAPG;
% c1 = (EvenHarmonics.*DFTMLG)'*DFTAPG + (EvenHarmonics.*DFTAPG)'*DFTMLG;
% c0 = (EvenHarmonics.*DFTMLG)'*DFTMLG;
% b2 = c0;
% b1 = c1;
% b0 = c2;
% d2 = a0;
% d1 = a1;
% d0 = a2;
% % we get:
% %   HR_Prod = (x.^2*a2 + x*a1 + a0) * (x.^2*b2 + x*b1 + b0) / (x.^2*c2 + x*c1 + c0) * (x.^2*d2 + x*d1 + d0)
% % or:
% %   HR_Prod =  N/D 
% % with
% %   N =      ( x.^4*(a2*b2)...
% %             +x.^3*(a2*b1+a1*b2)...
% %             +x.^2*(a2*b0+a1*b1+a0*b2)...
% %             +x   *(a1*b0+a0*b1)...
% %             +      a0*b0              )...
% % and with 
% %   D =      ( x.^4*(c2*d2)...
% %             +x.^3*(c2*d1+c1*d2)...
% %             +x.^2*(c2*d0+c1*d1+c0*d2)...
% %             +x   *(c1*d0+c0*d1)...
% %             +      c0*d0              )
% %   or D =   ( x.^4*(a0*b0)...
% %             +x.^3*(a1*b0+a0*b1)...
% %             +x.^2*(a2*b0+a1*b1+a0*b2)...
% %             +x   *(a2*b1+a1*b2)...
% %             +      a2*b2              )
% % or by substition of
% n4 = a2*b2;
% n3 = a2*b1+a1*b2;
% n2 = a2*b0+a1*b1+a0*b2;
% n1 = a1*b0+a0*b1;
% n0 = a0*b0;
% % d4 = n0;
% % d3 = n1;
% % d2 = n2;
% % d1 = n3;
% % d0 = n4;
% % we get 
% % N = sum(ni*x^i) and D=sum(di*x^i)
% % 
% % Then HR_Prod reaches a maximum or minimum when d/dx (N/D) = 0 
% % or (dN/dx)/D - N/(D^2)*(dD/dx) = 0
% % or (dN/dx)*D - (dD/dx)*N = 0
% % or
% %    x^7*(4*n4*d4 - 4*n4*d4)
% %  + x^6*(4*n4*d3 - 4*n3*d4 + 3*n3*d4 - 3*n4*d3)
% %  + x^5*(4*n4*d2 - 4*n2*d4 + 3*n3*d3 - 3*n3*d3 + 2*n2*d4 - 2*n4*d2)
% %  + x^4*(4*n4*d1 - 4*n1*d4 + 3*n3*d2 - 3*n2*d3 + 2*n2*d3 - 2*n3*d2 + 1*n1*d4 - 1*n4*d1)
% %  + x^3*(4*n4*d0 - 4*n0*d4 + 3*n3*d1 - 3*n1*d3 + 2*n2*d2 - 2*n2*d2 + 1*n1*d3 - 1*n3*d1)
% %  + x^2*(                    3*n3*d0 - 3*n0*d3 + 2*n2*d1 - 2*n1*d2 + 1*n1*d2 - 1*n2*d1)
% %  + x^1*(                                        2*n2*d0 - 2*n0*d2 + 1*n1*d1 - 1*n1*d1)
% %  + x^0*(                                                            1*n1*d0 - 1*n0*d1)
% %  = 0 
% % or
% %    x^6*(1*n4*d3 - 1*n3*d4)
% %  + x^5*(2*n4*d2 - 2*n2*d4)
% %  + x^4*(3*n4*d1 - 3*n1*d4 + 1*n3*d2 - 1*n2*d3)
% %  + x^3*(4*n4*d0 - 4*n0*d4 + 2*n3*d1 - 2*n1*d3)
% %  + x^2*(                    3*n3*d0 - 3*n0*d3 + 1*n2*d1 - 1*n1*d2)
% %  + x^1*(                                        2*n2*d0 - 2*n0*d2)
% %  + x^0*(                                                            1*n1*d0 - 1*n0*d1)
% %  = 0 
% % or
% %    (x^6+x^0) * (1*n4*n1 - 1*n3*n0)
% %  + (x^5+x^1) * (2*n4*n2 - 2*n2*n0)
% %  + (x^4+x^2) * (3*n4*n3 - 3*n1*n0 + 1*n3*n2 - 1*n2*n1)
% %  +  x^3      * (4*n4*n4 - 4*n0*n0 + 2*n3*n3 - 2*n1*n1)
% %  = 0 
% % or
% %    (x^6+x^0) * (1*(a2*b2)*(a1*b0+a0*b1) - 1*(a2*b1+a1*b2)*(a0*b0))
% %  + (x^5+x^1) * (2*(a2*b2)*(a2*b0+a1*b1+a0*b2) - 2*(a2*b0+a1*b1+a0*b2)*(a0*b0))
% %  + (x^4+x^2) * (3*(a2*b2)*(a2*b1+a1*b2) - 3*(a1*b0+a0*b1)*(a0*b0) + 1*(a2*b1+a1*b2)*(a2*b0+a1*b1+a0*b2) - 1*(a2*b0+a1*b1+a0*b2)*(a1*b0+a0*b1))
% %  +  x^3      * (4*(a2*b2)*(a2*b2) - 4*(a0*b0)*(a0*b0) + 2*(a2*b1+a1*b2)*(a2*b1+a1*b2) - 2*(a1*b0+a0*b1)*(a1*b0+a0*b1))
% %  = 0 
% % or
% %    (x^6+x^0) * (a2*b2*a1*b0 + a2*b2*b1*a0 - a2*b1*a0*b0 - b2*a1*a0*b0)
% %  + (x^5+x^1) * (2*(a2*a2*b2*b0+a2*b2*b2*a0+a2*b2*a1*b1) - 2*(a2*a0*b0*b0+b2*a0*a0*b0+a1*b1*a0*b0))
% %  + (x^4+x^2) * (3*a2*a2*b2*b1 +a2*a2*b1*b0 +3*a2*b2*b2*a1 +a2*b2*a1*b0 +a2*b2*b1*a0 +a2*a1*b1*b1 -a2*a1*b0*b0 -a2*a0*b1*b0 +b2*b2*a1*a0 +b2*a1*a1*b1 -b2*a1*a0*b0 -b2*b1*a0*a0 -a1*a1*b1*b0 -a1*b1*b1*a0 -3*a1*a0*b0*b0 -3*b1*a0*a0*b0)
% %  +  x^3      * (4*a2*a2*b2*b2 +2*a2*a2*b1*b1 +4*a2*b2*a1*b1 +2*b2*b2*a1*a1 -2*a1*a1*b0*b0 -4*a1*b1*a0*b0 -2*b1*b1*a0*a0 -4*a0*a0*b0*b0)
% %  = 0 
% % which can probably not be solved analytically?.

