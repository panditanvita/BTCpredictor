%find the similarity between two vectors

function s = vecsim(x,y)
    
    assert(length(x)==length(y),'these vectors are different lengths!');
    assert(~isempty(x),'need a larger vector');
    
    num = sum((x - mean(x)).*(y-mean(y)));
    den = length(x)*std(x)*std(y);
    
    if (den == 0)
       s = num; %to account for if either vector has std=0          
    else
       s = (num/den);
    end
    
end
        
    