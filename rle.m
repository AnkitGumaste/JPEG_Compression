function Output=rle(Input)
L=length(Input);
j=1;
k=1;
i=1;
while i<2*L
    comp=1;
    for j=j:L
        if j==L 
            break
        end 
         if Input(j)==Input(j+1)
            comp=comp+1;
        else
            break
         end
    end
        Output(k+1)=comp;
        Output(k)=Input(j);
        if j==L && Input(j-1)==Input(j) 
            break
        end  
        i=i+1;
        k=k+2;
        j=j+1;
        if j==L 
            if mod(L,2)==0 
            Output(k+1)=1;
            Output(k)=Input(j);
            else
            Output(k+1)=1;    
            Output(k)=Input(j);
            end
             break
        end
end