% This code loads the data in the provided format, estimates the number of
% right guesses and provides a consistency score (see paper for details on
% how this score is computed).
%
% Things to do/add:
%   -participant proficiency relative to random statistics
%
% This code complements the study: "You must be bluffing, Mr Mc Garrigle: 
% Challenging an amateur sommelier" by Maldonado and Zielinska.

clear variables; close all; clc

% files names:
mapping_file = 'maps.dat';
eddie_file = 'emcg.dat';

load(mapping_file)

% anti-drunk check:
checksums = sum(maps,1);
disp('Loading data...')
disp('Checking input data quality...')
if checksums(1) == sum(1:8) && checksums(1) == checksums(2) && ...
        checksums(1) == checksums(3) && checksums(1) == checksums(4)
    disp('Elements in input matrix make sense...')
else
    error('ERROR detected. Please sober up and try again.')
end

% Transformations to input matrix to compute the "keys":
[b,r] = size(maps); % b=bottles, r=rounds (counting round 0)
maps2 = zeros(b,r);
maps2(:,1:r) = maps(:,r:-1:1);
sorted = sortrows(maps2);
K1 = sorted(:,1:2);
K2 = sortrows(sorted(:,[1 3]));
K3 = sortrows(sorted(:,[1 4]));
resortK(:,:,1) = sortrows(K1,2);
resortK(:,:,2) = sortrows(K2,2);
resortK(:,:,3) = sortrows(K3,2);
% Matrix with keys per round (left to right):
Mkeys = zeros(b,r-1);
Mkeys(:,1:3) = resortK(:,1,1:3);

% --- Section for participants 

disp("Loading participants' guesses...")
eddie = load(eddie_file);
C = reshape(eddie,b,r-1,[]);
c = C(:,:,2);
% Matrix with keys/guess by this participant:
MkeysE = zeros(b,r-1);
for i=1:r-1
    MkeysE(:,i) = c(:,i);
end

% This and all participants have been confronted with the following labels:
Mconfr = (MkeysE./MkeysE).*((1:8)'*ones(1,3));
% ... which in reality are the following bottles:
Mconfr_dec = (Mconfr./Mconfr).*Mkeys;

% Required for consistency analysis: 
acounts = zeros(1,b);
for i=1:8
    acounts(i) = sum(sum(Mconfr_dec == i));
end

bcounts = zeros(1,r-1);
for i=1:r-1
    bcounts(i) = sum(acounts == i);
end

% check
if sum(bcounts.*[1 2 3]) ~= 15 
    error('ERROR detected. Please sober up and try again.')
end


% --- results per participant
% Eddie's right guesses per round:
Eright = sum(MkeysE./Mkeys == 1);

% Eddie's consistency score:
prov_scrE = zeros(b,b);
con_score = 0;
for i=1:b
    for j=1:b
        prov_scrE(i,j) = sum(sum((MkeysE==i)./(Mconfr_dec==j) == 1));
        %gain or lose:
        if prov_scrE(i,j)==2 && sum(sum(MkeysE==i))==sum(sum(Mconfr_dec==j))...
                && prov_scrE(i,j) == sum(sum(Mconfr_dec==j))
            con_score = con_score + prov_scrE(i,j)-1;
        elseif prov_scrE(i,j)==3 && sum(sum(MkeysE==i))==sum(sum(Mconfr_dec==j))...
                && prov_scrE(i,j) == sum(sum(Mconfr_dec==j))
            con_score = con_score + prov_scrE(i,j);
        end
    end
end
con_scoreE = con_score;

% Required for consistency analysis: 
acountsE = zeros(1,b);
for i=1:8
    acountsE(i) = sum(sum(MkeysE == i));
end


disp(' ')
disp('----------- Results summary ----------------- ')
disp("Eddie's correct guesses per round:")
disp(Eright)
disp(['(',num2str(sum(Eright)),' correct guesses in total)'])
disp(' ')
disp("Eddie's consistency score is:")
disp(con_scoreE)


%date and time:
tnow = datetime;
tnows = datestr(tnow);

h1 = '====================================\n';
sign = ['\n\nReport created on ' tnows '\n\n'];

fid = fopen('full_report.txt','w');
fprintf(fid, h1);
fprintf(fid, '\nDetailed report on the experiment\n');
fprintf(fid, sign);
fprintf(fid, h1);
fprintf(fid, '\nThe participants have been confronted with:\n');
fprintf(fid,['\t',num2str(bcounts(1)),' time(s) with a unique bottle\n']);
fprintf(fid,['\t',num2str(bcounts(2)),' time(s) with a bottle twice\n']);
fprintf(fid,['\t',num2str(bcounts(3)),' time(s) with a bottle thrice\n']);
fprintf(fid, '\nIn particular:\n\n');
fprintf(fid,['\tBottle 1 appeared ',num2str(acounts(1)),' time(s)\n']);
fprintf(fid,['\tBottle 2 appeared ',num2str(acounts(2)),' time(s)\n']);
fprintf(fid,['\tBottle 3 appeared ',num2str(acounts(3)),' time(s)\n']);
fprintf(fid,['\tBottle 4 appeared ',num2str(acounts(4)),' time(s)\n']);
fprintf(fid,['\tBottle 5 appeared ',num2str(acounts(5)),' time(s)\n']);
fprintf(fid,['\tBottle 6 appeared ',num2str(acounts(6)),' time(s)\n']);
fprintf(fid,['\tBottle 7 appeared ',num2str(acounts(7)),' time(s)\n']);
fprintf(fid,['\tBottle 8 appeared ',num2str(acounts(8)),' time(s)\n']);
fprintf(fid, '\nThe bottles decoded per round are as follows (Lb=label):\n\n');
fprintf(fid, 'Lb\t R1\t R2\t R3\n');
fprintf(fid,'%i\t %i\t %i\t %i\n',[(1:8)' Mkeys]');
fprintf(fid, '\nRemoving the bottles that did not participate:\n\n');
fprintf(fid, 'Lb\t R1\t R2\t R3\n');
fprintf(fid,'%i\t %i\t %i\t %i\n',[(1:8)' Mconfr_dec]');
fprintf(fid, '\n');
fprintf(fid, h1);
fprintf(fid, '\tResults per participant\n');
fprintf(fid, h1);
fprintf(fid, '\n\tParticipant: The subject\n');
fprintf(fid, '\nGuesses per round (Lb = label):\n\n');
fprintf(fid, 'Lb\t R1\t R2\t R3\n');
fprintf(fid,'%i\t %i\t %i\t %i\n',[(1:8)' MkeysE]');
fprintf(fid, '\nMatrix of correct guesses per round:\n\n');
fprintf(fid, 'R1\t R2\t R3\n');
fprintf(fid,'%i\t %i\t %i\n',[MkeysE./Mkeys==1]');
fprintf(fid,['\nTherefore, total number of correct guesses is: ',...
    num2str(sum(Eright))]);
fprintf(fid, '\nwhich makes this participant XXXcompare vs randomXX\n');
fprintf(fid, '\n---Consistency\n');
fprintf(fid, '\nThe following matrix with i rows, j columns, and elements (i,j) is interpreted as follows:\n');
fprintf(fid, 'This participant guessed that bottle j was i precisely (i,j) times. \n');
fprintf(fid, 'NOTE: only values >1 are relevant for the consistency score.\n');
fprintf(fid, '\b \b \b \b (evidently, the trace of this matrix equals the number of correct guesses.)\n\n');

fprintf(fid, '\b \b \b 1\t 2\t 3\t 4\t 5\t 6\t 7\t 8\n');
fprintf(fid, '-----------------------------------------------------------\n');
fprintf(fid,'%i\b |%i\t %i\t %i\t %i\t %i\t %i\t %i\t %i\n',[(1:8)' prov_scrE]');
fprintf(fid, '\nThe following matrix gives the number Np that a given bottle Bt participated,\n');
fprintf(fid, 'as well as the number of times Ik that said bottle was invoked by the participant:\n\n');
fprintf(fid, 'Bt\t Np\t Ik\n');
fprintf(fid,'%i\t %i\t %i\n',[(1:8)' acounts' acountsE']');
fprintf(fid,['\nThus, the consistency score for this participant is: ',num2str(con_scoreE)]);

fprintf(fid, '\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n');
fprintf(fid, '\n\tParticipant: XX\n');
% do the same for all other participants...

fclose(fid);

        
