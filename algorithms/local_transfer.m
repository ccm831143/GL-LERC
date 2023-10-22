function [solution_sel,idx_source,candidates_transfer,simlarity_values] = ...
    local_transfer(target_population,target_fitness,lb,ub,gen,knowledge_base,target_population_previous,target_fitness_previous)

num_sources = length(knowledge_base);
[popsize,dim] = size(target_population);
target_population_normalized = (target_population-repmat(lb,popsize,1))./...
    (repmat(ub,popsize,1)-repmat(lb,popsize,1));

simlarity_values = zeros(num_sources,1);
candidates_transfer = zeros(num_sources,dim);
for i = 1:num_sources
    source_solutions = knowledge_base(i).solutions;
    source_fitnesses = knowledge_base(i).fitnesses;
    gen_max_source = length(source_solutions);
    if gen == 1
        simlarity_values = rand(num_sources,1);
        candidates_transfer = rand(num_sources,dim);
    else
        num_nearest_neighbors = 1;
        delta = 3;
        target_population_normalized_previous = (target_population_previous-...
            repmat(lb,popsize,1))./(repmat(ub,popsize,1)-repmat(lb,popsize,1));
        source_population_ori = [source_solutions{gen-1};source_solutions{gen}];
        source_fitness_ori = [source_fitnesses{gen-1};source_fitnesses{gen}];
        target_population_ori = [target_population_normalized_previous;target_population_normalized];
        target_fitness_ori = [target_fitness_previous;target_fitness];
        source_mean = source_population_ori-repmat(mean(source_population_ori),2*popsize,1);
        target_mean = target_population_ori-repmat(mean(target_population_ori),2*popsize,1);
        [coe_source,~,latent_source] = pca(source_mean);
        [coe_target,~,latent_target] = pca(target_mean);
        scalar = latent_target(1)/latent_source(1);
        scaling_operation = coe_source*sqrt(scalar)/coe_source;
        rotation_operation = coe_source'*coe_target;
        skeleton_size = 20;
        random_sequence = randperm(2*popsize);
        source_local = source_population_ori(random_sequence(1:skeleton_size),:);
        source_fitness_local = source_fitness_ori(random_sequence(1:skeleton_size));
        source_encoding = zeros(1,skeleton_size);
        for p = 1:skeleton_size
            source_encoding(p) = length(find(source_fitness_local<source_fitness_local(p)))+1;
        end
        source_local_mean = source_local-repmat(mean(source_population_ori),skeleton_size,1);
        source_transform = repmat(mean(target_population_ori),skeleton_size,1)+...
            source_local_mean*scaling_operation*rotation_operation;
        fitness_encoding = zeros(skeleton_size,1);
        for p = 1:skeleton_size
            dis = zeros(1,2*popsize);
            for q = 1:2*popsize
                dis(q) = norm(source_transform(p,:)-target_population_ori(q,:),1);
            end
            [~,idx] = sort(dis);
            fitness_encoding(p) = mean(target_fitness_ori(idx(1:num_nearest_neighbors)));
        end
        target_encoding = zeros(1,skeleton_size);
        for p = 1:skeleton_size
            target_encoding(p) = length(find(fitness_encoding<fitness_encoding(p)))+1;
        end
        source_transform_all = repmat(mean(target_population_ori),2*popsize,1)+...
            source_mean*scaling_operation*rotation_operation;
        [~,~,latent_source_transformed] = pca(source_transform_all);
        uncertainty_level = 1 - sum(abs(latent_source_transformed-latent_target))/sum(latent_target);
        simlarity_values(i) = uncertainty_level*mySpearman(source_encoding,target_encoding);
        if gen+delta<=gen_max_source
            [~,idx_tr] = min(source_fitnesses{gen+delta});
            source_transform_transfer = (source_solutions{gen+delta}(idx_tr,:)-...
                mean(source_population_ori))*scaling_operation*rotation_operation+mean(target_population_ori);
        else
            [~,idx_tr] = min(source_fitnesses{gen_max_source});
            source_transform_transfer = (source_solutions{gen_max_source}(idx_tr,:)-...
                mean(source_population_ori))*scaling_operation*rotation_operation+mean(target_population_ori);
        end
        candidates_transfer(i,:) = source_transform_transfer;
        candidates_transfer(i,candidates_transfer(i,:)<0) = 0;
        candidates_transfer(i,candidates_transfer(i,:)>1) = 1;
    end
end
[~,idx_source] = max(simlarity_values);
solution_sel = lb+(ub-lb).*candidates_transfer(idx_source,:);