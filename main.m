clc,clear
warning off;
task_families = {'Sphere','Ellipsoid','Schwefel','Quartic','Ackley','Rastrigin','Griewank','Levy'}; % eight task families
transfer_scenarios = {'a','e'}; % intra-family and inter-family transfers
similarity_distributions = {'h1','h2','m1','m2','m3','m4','l1','l2'}; % eight similarity distributions
k = 1000; % the number of previously-solved source tasks
folder_problems = './benchmarks';
specifications = [1 1 1 50 k; % STOP 1
    2 2 2 25 k; % STOP 2
    3 1 2 30 k; % STOP 3
    4 2 1 50 k; % STOP 4
    5 1 3 25 k; % STOP 5
    6 2 4 50 k; % STOP 6
    7 1 5 25 k; % STOP 7
    8 2 6 30 k; % STOP 8
    1 1 7 25 k; % STOP 9
    6 2 8 30 k; % STOP 10
    5 1 8 50 k; % STOP 11
    2 2 7 50 k]; % STOP 12
num_problems = size(specifications,1); % the number of individual benchmark problems
optimizer = 'ea'; % evolutionary optimizer
popsize = 50; % population size
FEsMax = 2500; % the number of function evaluations available
runs = 30; % the number of independent runs
metrics = {'Global&Local', 'Local', 'Global'}; %  global and local similarity metrics
opts_sesto.gen_trans = 1; % the generation gap of periodically triggering the knowledghe transfer
runs_total = size(opts_sesto.metrics,1)*num_problems*runs;
count = 0*num_problems*runs;

for a = 1:size(opts_sesto.metrics)
    for n = 1:num_problems
        results_opt = struct;
        for r = 1:runs
            % import the black-box STO problem to be solved
            stop_tbo = STOP('func_target',task_families{specifications(n,1)},...
        		'trans_sce',transfer_scenarios{specifications(n,2)},...
        		'sim_distribution',similarity_distributions{specifications(n,3)},...
       		 'dim',specifications(n,4),...
       		 'k',specifications(n,5),...
       		 'optimizer',optimizer,...
       		 'FEsMax',FEsMax,...
        		'mode','opt',...
        		'folder_stops',folder_problems);
            target_task = stop_tbo.target_problem;
            knowledge_base = stop_tbo.knowledge_base;
            problem.fnc = target_task.fnc;
            problem.lb = target_task.lb;
            problem.ub = target_task.ub;
            
            % parameter configurations of the sesto solver
            opts_sesto.metric = metrics(a);
            opts_sesto.knowledge_base = knowledge_base;
            [solutions,fitnesses] = sesto_optimizer(problem,popsize,FEsMax,...
                optimizer,opts_sesto);
            results_opt(r).solutions = solutions;
            results_opt(r).fitnesses = fitnesses;
            count = count+1;
            
            fprintf(['Algorithm: ','S-',opts_sesto.metrics{a},'+A-N, STOP-',...
                num2str(n),', run: ',num2str(r),'\n']);
            %waitbar(count/runs_total,h,sprintf('Optimization in progress: %.2f%%',...
                %count/runs_total*100));
        end
        % save the results
        save(['./results/',task_families{specifications(n,1)},'-T',...
            transfer_scenarios{specifications(n,2)},...
            '-S',similarity_distributions{specifications(n,3)},'-d',num2str(specifications(n,4)),...
            '-k',num2str(specifications(n,5)),'-S-',opts_sesto.metrics{a},...
            '+A-N.mat'],'results_opt');
    end
end
%close(h);