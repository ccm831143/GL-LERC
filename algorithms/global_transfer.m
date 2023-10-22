function idx_gtran = global_transfer(fitness_initial, knowledge_base)
    eng_target = values2ranks(fitness_initial);
    eng_sources = zeros(num_sources,popsize);
    rank_corrs = zeros(num_sources,1);
    for i = 1:num_sources
        eng_sources(i,:) = values2ranks(knowledge_base(i).fitnesses{1});
        rank_corrs(i) = mySpearman(eng_target,eng_sources(i,:));
    end
    [~,idx_max] = max(rank_corrs);
    dis_solutions = zeros(1,num_sources);
    idx_gtran = zeros(FEsMax/popsize, 1);
    idx_gtran(1) = idx_max;
    for i = 2:length(idx_gtran)
        for k = 1:num_sources
            flag = 0;
            for j = 1:i-1
                if k == idx_gtran(j)
                    flag = 1;
                    break
                end
            end
            if flag == 0
                dis_solutions(k) = norm(knowledge_base(idx_gtran(i-1)).solutions{end}(randi(popsize),:)-knowledge_base(k).solutions{end}(randi(popsize),:),1);
            else
                dis_solutions(k) = 1000;
            end
        end
        [~,temp_min] = min(dis_solutions);
        idx_gtran(i) = temp_min;
    end
end