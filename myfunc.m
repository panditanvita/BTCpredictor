function f = myfunc(x,r)
g1=x(8);
g2=x(9)-x(10);
g3=x(10);
g4=x(7);
g5=x(9);
g6=x(2);
if(g1<=0||g2<0||g3<0||g4<0||g5>=1||g6<0)
    f=10000;
else
t=length(r);
mu=x(1);
omega=x(2);
alpha=x(3);
alphaj=x(4);
alphaa=x(5);
alphaaj=x(6);
beta=x(7);
lamda0=x(8);
rho=x(9);
gama=x(10);
theta=x(11);
delta=x(12);

sigma=zeros(t,1);
lamda=zeros(t,1);
f3=zeros(t,1);
abxlong=zeros(t,1);
g=zeros(t,1);
xp=20;
% proba=zeros(t,1);
p=zeros(t,xp+1);
for i=1:t

%     if i==13;
%        i=13; 
%     end
       E=0;
    if i==1
        
       abxlong(i)=0; 
    else    
        for j=0:xp 
        %计算E
        E=E+j*p(i-1,j+1);
        end
        abxlong(i)=E-lamda(i-1);
        if(r(i-1)-mu<0)
        g(i)=exp(alpha+alphaj*E+alphaa+alphaaj*E);
        else
        g(i)=exp(alpha+alphaj*E);    
        end
        
    end
    
   if(i==1)
    lamda(i)=lamda0/(1-rho);
    sigma(i)=omega;
   else
    lamda(i)=lamda0+rho*lamda(i-1)+gama*abxlong(i);
    sigma(i)=omega+g(i)*((r(i-1)-mu)^2)+beta*sigma(i-1);   
       
   end
   
   
   
   sums=0;
   for j=0:xp 
       x1=1/(sqrt(2*pi*(sigma(i)+j*delta*delta)));
       s1=(r(i)-mu+theta*lamda(i)-theta*j);
       s2=2*(sigma(i)+j*delta*delta);
       x2=exp(-s1*s1./s2);
       x3=exp(-lamda(i))*(lamda(i)^j)/factorial(j);
       sums=sums+x1*x2*x3;
   end
    f3(i)=log(sums);
   %计算当日事后概率分布
   for j=0:xp 
       x1=1/(sqrt(2*pi*(sigma(i)+j*delta*delta)));
       s1=(r(i)-mu+theta*lamda(i)-theta*j);
       s2=2*(sigma(i)+j*delta*delta);
       x2=exp(-s1*s1./s2);
       x3=exp(-lamda(i))*(lamda(i)^j)/factorial(j);
       p(i,j+1)=x1*x2*x3/sums;
   end
   
%    proba(i)=sum(p(i,2:end));
   
end

f=-sum(f3(2:end));


end

end