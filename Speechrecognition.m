%close all
load handel.mat
[y,Fs]=audioread('2_Uzair_0.wav');
%sound(y,Fs);
t=0:1/Fs:(length(y)-1)/Fs;
dataset=[];%training data set
input=[];%input data
%figure(1);
%plot(y);sound
BPimp=impz(BP);%Bandpass filter to remove noise 
y=conv(y,BPimp);
figure
spectrogram(y,300,280,200,Fs,'yaxis');
title('Original Signal')
t=0:1/Fs:(length(y)-1)/Fs;
%dataset=conv(dataset,BPimp);
%input=conv(input,BPimp);
%TFL=floor(length(y)/80);%time frame length
%LTFL=length(y)-TFL*79;%last time frame length
TFL=0.005*Fs;%samples per time frame of 10ms
NTF=ceil(length(y)/TFL);%Number of time frames
if(mod(length(y),TFL)==0)
    LTFL=TFL;
else
    LTFL=mod(length(y),TFL);%Samples in last time frame
end
ys=[];%y slit into time frames
ystemp=[];
pointer=1;
Ys=[];
H=[];
E=[];
for i=1:1:NTF
   if i==NTF
       ystemp=[ystemp;y(pointer:end)];
       ys{i}=ystemp;
       Ys=fft(ystemp);
       s=(1/(2*pi)).*(abs(Ys)).^2;%Spectral energy
       E=[E,log10(sum(s))];
       p=s./sum(s);%Probabilty density function
       H=[H;-sum(p.*log2(p))];%Enthropy value function
       pointer=pointer+LTFL;
   else
       ystemp=[ystemp;y(pointer:i*TFL)];
       ys{i}=ystemp;
       Ys=fft(ystemp);
       s=(1/(2*pi)).*(abs(Ys)).^2;%Spectral energy
       E=[E,log10(sum(s))];
       p=s./sum(s);%Probabilty density function
       H=[H;-sum(p.*log2(p))];%Enthropy value function 
       pointer=pointer+TFL;
   end
   ystemp=[];
end
%Y=fft(y);
%{
figure
subplot(2,1,1);
plot(abs(Y));
subplot(2,1,2);
deltat=1/Fs;
N=length(Y);
df=1/(N*deltat);
if mod(N,2)==0 %N is even
    f_axis=(-N/2:N/2-1)*df;
else %N is odd
    f_axis=(-(N-1)/2:(N-1)/2)*df;
end
plot(f_axis,fftshift(abs(Y)));
xlabel('Frequancy(Hz)');
ylabel('Magnitude of Y');
%}
%{
s=(1/(2*pi)).*(abs(Y)).^2;%Spectral energy
p=s./sum(s);%Probabilty density function
H=sum(-p.*log10(p));%Enthropy value function
t=0:1/Fs:(length(y)-1)/Fs;
%}
%l=(max(H)-min(H))/2;
%lambda=(max(H)+min(H))/2;%test lambda
%{
figure
plot(H);
title('Enthropy');
%}
max=1440;
figure
plot(E);
title('Spectral Energy');
%speech_start=find(H<=lambda, 1);
speech_start=find(E>=-3, 1);
speech_start_time=speech_start*TFL/Fs;
%speech_end=(find(H(speech_start:end)<=lambda, 1,'last' ))+speech_start;
speech_end=(find(E(speech_start:end)>=-3, 1,'last'))+speech_start-1;
speech_end_time=speech_end*TFL/Fs;
if(speech_end*TFL>length(y))
    ynew=y(speech_start*TFL:end);
else
    ynew=y(speech_start*TFL:speech_end*TFL);
end    
figure
spectrogram(ynew,300,280,200,Fs,'yaxis')
title('Speech extraction');
%sound(ynew,Fs);
%Working out MFCC
% [MFCC,tc]=v_melcepst(ynew,Fs,'M',15);
% [rows,columns]=size(MFCC);
%MFCC=sum(MFCC,1)./rows;
%M = mean(MFCC);
%S = std(MFCC,[],1);
%MFCC = (MFCC-M)./S;
% MFCC=reshape(MFCC',[1 size(MFCC,1)*size(MFCC,2)]);
% MFCC=[MFCC,zeros(1,max-(length(MFCC)))];
cepFeatures=cepstralFeatureExtractor('SampleRate',Fs);
release(cepFeatures);
cepFeatures.NumCoeffs=13;
cepFeatures.LogEnergy='Ignore';
[coeffs]=cepFeatures(ynew);
figure
plot(coeffs);
% win = hann(1024,'periodic');
% S   = stft(ynew,'Window',win,'OverlapLength',512,'Centered',false);
% mcoeffs = mfcc(S,Fs);

%close all
%figure
%plot(MFCC)
%title('Mel coeffecients');