function [osuDataTarget,osuDataTiming] = getOsuDataTarget(s)

% This function is for generating the targets to the neural network, as a
% formatized data of the the beatmap created by humans.
% 
% Specially designed for convolution NN "FrostNova" Ver1
% -----------Input------------ 
% Ts: the rhythm poitns of the song, Ts=Ts=getRhythmPoints(s), where s
% is the osu structure.
% osuObj: the objects of the map, osuObj=osuObjectParser(s);
% -----------Output------------
% osuDataTarget: A Tensor of target for TENSORFLOW, each data set has 4
% dimensions: {isCircle, isSliderHead, is SliderEnd, empty}
% 
% -----------------------
% By Dongqi Han, OIST

Ts=getRhythmPoints(s);
osuObj=osuObjectParser(s);

osuDataTarget=zeros(length(Ts),4);
osuDataTiming=zeros(length(Ts),1);

z0=1;
while osuObj(z0).timing<Ts(1)
    z0=z0+1;
end

n=1;
    
for z=z0:length(osuObj) 
    
    
    while n<length(Ts)&&abs(osuObj(z).timing-Ts(n))>3&&(Ts(n)-osuObj(z).timing<10)
        n=n+1;
    end
    
    if n>=length(Ts)
        break;
    end
    
    if n>1 && abs(osuObj(z).timing-Ts(n))<3
        switch osuObj(z).type
            case 'circle'
                osuDataTarget(n,1)=1; % circle
            case 'slider'
                
                if osuObj(z).turns>1
                    for k=0:osuObj(z).turns
                        osuDataTarget(n+k*(osuObj(z).length),1)=1; %regard returning sliders as circles
                    end
                else
                    osuDataTarget(n,2)=1; % silderHead
                    osuDataTarget(n+osuObj(z).length,3)=1; %sliderEnd
                end
            case 'spinner'
                osuDataTarget(n,2)=1; %regard spinnerHead as SliderHead
            otherwise
                
        end
        osuDataTiming(n)=osuObj(z).timing;
    end
    
    

    n=n+1;
    
    
end

for i = 1:length(Ts)
    if sum(osuDataTarget(i,1:3),2)==0
        osuDataTarget(i,4)=1;
    end
end

end

