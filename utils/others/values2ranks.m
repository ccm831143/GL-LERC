function ranks = values2ranks(values)
ranks = zeros(1,length(values));
for i = 1:length(values)
    ranks(i) = length(find(values<values(i)))+1;
end