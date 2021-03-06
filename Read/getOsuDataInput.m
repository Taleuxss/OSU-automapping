function [input,TS,TQ,FQ] = getOsuDataInput(s,songfile)

% This function is for generating the inputs to the neural network, as a
% formatized data of the songfile.
% 
% Specially designed for convolution NN "FrostNova" Ver1
% -----------Input------------ 
% Ts: the rhythm poitns of the song, Ts=Ts=getRhythmPoints(s), where s
% is the osu structure.
% songfile: the path of the music file.
% -----------Output------------
% osuDataInput: A Tensor of input for TENSORFLOW, each data set contains
% the matrix of spectrogram around a rhythm point.
% 
% -----------------------
% By Dongqi Han, OIST

t_reso = 15; % temporal resolution estimation(in milisecond) 
N_t = 128; % divide 
P = 4;
fq=linspace(0,10000,128); %range of frequency

%----------- read data -------------
[data0,fs]=audioread(songfile);
data1=data0(:,1); %left channel
data2=data0(:,2); %right channel

Nfft=round(fs/(1000/(t_reso))); 
window=hann(2*Nfft+1); 

[S1,~,~]=spectrogram(data1,window,[],Nfft,fs);

S1 = log(1+abs(S1));
S1 = S1 / max(max(S1)); %normalize

[S2,f,t]=spectrogram(data2,window,[],Nfft,fs);
t=t*1000; %convert to ms
t=t-t_reso;%modify

S2 = log(1+abs(S2));
S2 = S2 / max(max(S2)); %normalize

S=(S1+S2)/2;



Ts=getRhythmPoints(s);


osuDataInput=zeros(length(Ts),length(fq),N_t,'gpuArray'); %Input Tensor



% for n=1:length(Ts) %drop the first and last timing points.
%     
%     tq(1:N_t+1)=linspace(Ts(n-1),Ts(n),N_t+1);
%     tq(N_t+1:2*N_t+1)=linspace(Ts(n),Ts(n+1),N_t+1);
% 
%     tmp=interp1(T,S_t,tq);
%     
%     osuDataInput(n,n-1)=tmp/max(tmp);
%     
% end


[TS,~]=meshgrid(Ts,f);
[T,F]=meshgrid(t,f);

Sg=gpuArray(S);
Tg=gpuArray(T);
Fg=gpuArray(F);

for n=1:length(Ts)
    tq=linspace(Ts(max(n-P,1)),Ts(min(n+P,length(Ts))),N_t);

    [TQ,FQ]=meshgrid(tq,fq);
    TQg=gpuArray(TQ);
    FQg=gpuArray(FQ);
    
    osuDataInput(n,:,:)=interp2(Tg,Fg,Sg,TQg,FQg);
    osuDataInput(n,:,:)=osuDataInput(n,:,:)/max(max(osuDataInput(n,:,:)));
    if mod(n,100)==1
        n
    end
end

input=gather(osuDataInput);

end