%Test multiple samples in TestSample folder
load handel.mat
path = 'Modeltestdata';
files = dir (strcat(path,'\*.wav'));
L = length (files);
output_data=[];
output_target_data=[];
BPimp=impz(BP);%Bandpass filter to remove noise 
max=1440;
tind=[];
[yref,Fs]=audioread(strcat(path,'\',files(1).name));
targ=0;
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
    ys=[];%y split into time frames
    ystemp=[];
    pointer=1;
    Ys=[];
    E=[];
    for i=1:1:NTF
        if i==NTF
            ystemp=[ystemp;y(pointer:length(y))];
            ys{i}=ystemp;
            Ys=fft(ystemp);
            s=(1/(2*pi)).*(abs(Ys)).^2;%Spectral energy
            E=[E,log10(sum(s))];
            p=s./sum(s);%Probabilty density function
            pointer=pointer+LTFL;
        else
            ystemp=[ystemp;y(pointer:i*TFL)];
            ys{i}=ystemp;
            Ys=fft(ystemp);
            s=(1/(2*pi)).*(abs(Ys)).^2;%Spectral energy
            E=[E,log10(sum(s))];
            p=s./sum(s);%Probabilty density function
            pointer=pointer+TFL;
        end
        ystemp=[];
    end
    speech_start=find(E>=-3, 1);
    speech_start_time=speech_start*TFL/Fs;
    speech_end=(find(E(speech_start:length(E))>=-3, 1,'last'))+speech_start-1;
    speech_end_time=speech_end*TFL/Fs;
    if(speech_end*TFL>length(y))
        ynew=y(speech_start*TFL:end);
    else
        ynew=y(speech_start*TFL:speech_end*TFL);
    end  
    %{
    if(targ~=str2double(filename(1)))
       targ=str2double(filename(1));
       yref=cell2mat(ref(targ+1));
    end
    [DIST IX IY]=dtw(yref,ynew);%yref from training dat processing file
    ynew=ynew(IY);
    %}
    cepFeatures=cepstralFeatureExtractor('SampleRate',Fs);
    release(cepFeatures);
    cepFeatures.NumCoeffs=13;
    cepFeatures.LogEnergy='Ignore';
    [coeffs]=cepFeatures(ynew);
    output_data=[output_data;coeffs'];
    output_target_data=[output_target_data,str2double(filename(1))];
end
dlmwrite('Modeltestdata.csv',output_data(1,:),'delimiter',',');
dlmwrite('Modeltestdata.csv',output_data,'delimiter',',','-append');
%dlmwrite('targetdata.csv',target_data,'delimiter',',','-append');
dlmwrite('Modeltesttargetdata.csv',output_target_data,'delimiter',',');
dlmwrite('Modeltesttargetdata.csv',output_target_data,'delimiter',',','-append');