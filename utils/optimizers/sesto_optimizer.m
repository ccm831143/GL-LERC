function [solutions,fitnesses] = sesto_optimizer(problem,popsize,FEsMax,optimizer,paras)

% initialization
fun = problem.fnc;
lb = problem.lb;
ub = problem.ub;
metric = paras.metric; % the list of similarity metrics in solution selection
gen_trans = paras.gen_trans; % the generation gap of periodically triggering the knowledghe transfer
knowledge_base = paras.knowledge_base; % the knowledge base containing the evaluated solutions of k source tasks

solutions = cell(FEsMax/popsize,1);
fitnesses = cell(FEsMax/popsize,1);
if strcmp(metric,'Global') || strcmp(metric,'Global&Local') % initialize the population using the loaded skeleton
    load(['skeletonD',num2str(length(lb)),'N',num2str(popsize),'.mat']);
    population = repmat(lb,popsize,1)+skeleton.*(repmat(ub,popsize,1)-repmat(lb,popsize,1));
else
    population = lhsdesign_modified(popsize,lb,ub);
end

fitness = zeros(popsize,1);
for i = 1:popsize % function evaluation
    fitness(i) = fun(population(i,:));
end
FEsCount = popsize;
gen = 1; % the generation count
solutions{gen} = (population-repmat(lb,popsize,1))./(repmat(ub,popsize,1)-...
    repmat(lb,popsize,1)); % convert the solutions into the unified search space
fitnesses{gen} = fitness;


if strcmp(metric,'Global') || strcmp(metric,'Global&Local')
    idx_gtran = global_transfer(fitnesses{1}, knowledge_base);
end


target_population_previous = [];
target_fitness_previous = [];

while FEsCount < FEsMax
    
    % offspring generation using the specified operator
    population_parent = population;
    fitness_parent = fitness;
    offspring_generation_command = ['population_child = ',optimizer,...
        '_generator(population_parent,lb,ub);'];
    eval(offspring_generation_command);
    
    % the S-ESTO module
    if mod(gen,gen_trans) == 0
        solution_transfer = [];
            if strcmp(metric,'Global&Local')
                solution_transfer = lb+(ub-lb).*knowledge_base(idx_gtran(gen)).solutions{end}(randi(popsize),:);
                trans_local = local_transfer(population_parent,fitness_parent,lb,ub,gen,...
                    knowledge_base,target_population_previous,target_fitness_previous);
                solution_transfer = [solution_transfer;trans_local];
            elseif strcmp(metric,'Global')
                solution_transfer = lb+(ub-lb).*knowledge_base(idx_gtran(gen)).solutions{end}(randi(popsize),:);
            elseif strcmp(metric,'local')
                solution_transfer = local_transfer(population_parent,fitness_parent,lb,ub,gen,...
                    knowledge_base,target_population_previous,target_fitness_previous);
            end

        if ~isempty(solution_transfer)
            idx = randperm(popsize);
            population_child(idx(1:size(solution_transfer,1)),:) = solution_transfer;
        end
    end
    
    % offspring evaluation
    fitness_child = zeros(popsize,1);
    for i=1:popsize
        fitness_child(i) = fun(population_child(i,:));
    end
    FEsCount = FEsCount+popsize;
    gen = gen+1;
    target_population_previous = population_parent;
    target_fitness_previous = fitness_parent;
    
    % selection phase
    selection_command = ['[population,fitness]=',optimizer,...
        '_selector(population_parent,fitness_parent,population_child,fitness_child);'];
    eval(selection_command)
    
    % update the records
    solutions{gen} = (population-repmat(lb,popsize,1))./(repmat(ub,popsize,1)-...
        repmat(lb,popsize,1));
    fitnesses{gen} = fitness;
    
end