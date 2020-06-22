load handel.mat
%path = 'C:\Users\Mohamed Zahier\Documents\UCT\4th year\EEE4114F\project\Speech recognition\recordings';
%path = 'recordings';
path = 'GithubTrainingData';
files = dir (strcat(path,'\*.wav'));
L = length (files);
training_data=[];
target_data=[];
temp_data={};
BPimp=impz(BP);%Bandpass filter to remove noise 
max=0;
tind=[];
[yref,Fs]=audioread(strcat(path,'\',files(1).name));
targ=0;
ref={};
ref=[ref;yref'];
for j=1:L
    filename=files(j).name;
    [y,Fs]=audioread(strcat(path,'\',files(j).name));
    y=conv(y,BPimp);
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
    E=[];
    H=[];
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
    speech_start=find(E>=-3, 1);
    speech_start_time=speech_start*TFL/Fs;
    speech_end=(find(E(speech_start:end)>=-3, 1,'last'))+speech_start-1;
    speech_end_time=speech_end*TFL/Fs;
    ynew=y(speech_start*TFL:speech_end*TFL);
    %{
    [MFCC,tc]=v_melcepst(ynew,Fs,'M',15);
    [rows,columns]=size(MFCC);
    if(length(tc)*columns>max)
        max=length(tc)*columns;
    end
    if(length(tc)*columns>=1440)
        tind=[tind,j];
    end    
    %MFCC=sum(MFCC,1)./rows;
    sub_data=reshape(MFCC',[1 size(MFCC,1)*size(MFCC,2)]);
    %}
    %Change referance example based on input number
    %{
    if(targ~=str2double(filename(1)))
       targ=str2double(filename(1));
       [yref,Fs]=audioread(strcat(path,'\',files(j).name));
       ref=[ref;yref'];
    end
    %}
    %Dynamic time warping
    %[DIST IX IY]=dtw(yref,ynew);
    %ynew=ynew(IY);
    cepFeatures=cepstralFeatureExtractor('SampleRate',Fs);
    release(cepFeatures);
    cepFeatures.NumCoeffs=13;
    cepFeatures.LogEnergy='Ignore';
    [sub_data]=cepFeatures(ynew);
    %temp_data{j}=sub_data;
    training_data=[training_data;(sub_data)'];
    target_data=[target_data,str2double(filename(1))];
end
%{
for i=1:length(target_data)
    sub_data=cell2mat(temp_data(i));
    sub_data=[sub_data,zeros(1,max-(length(sub_data)))];%Pad zeroes
    training_data=[training_data;sub_data];
end    
%}
dlmwrite('trainingdata.csv',training_data(1,:),'delimiter',',');%To account for google colab making first row headings
dlmwrite('trainingdata.csv',training_data,'delimiter',',','-append');
%dlmwrite('targetdata.csv',target_data,'delimiter',',','-append');
dlmwrite('targetdata.csv',target_data,'delimiter',',');
dlmwrite('targetdata.csv',target_data,'delimiter',',','-append');