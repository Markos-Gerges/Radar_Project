clear all
clc;

% Radar Specifications
%%%%%%%%%%%%%%%%%%%%%%%%%%%
frequency = 77e9; % carrier frequency 77GHz Radar
Max_Range = 200;
Range_Resolution = 1;
% Max Velocity = 100 m/s
%%%%%%%%%%%%%%%%%%%%%%%%%%%

speed_of_light = 3e8

% User Defined Range and Velocity of target
%TODO : define the target's initial position and velocity. Note : Velocity remains contant
R=110; %initial distance of the target
v=-2; %speed of the target

% FMCW Waveform Generation
% *%TODO* :
%Design the FMCW waveform by giving the specs of each of its parameters.
% Calculate the Bandwidth (B), Chirp Time (Tchirp) and Slope (slope) of the FMCW
% chirp using the requirements above.

%Sweep time for each chirp is defined as rule by 5.5 time of round trip
%time for Maximum Range
Sweep_Time = 5.5*2*Max_Range/speed_of_light;

%Bandwidth for the each chrip for given resolution
Bandwidth = speed_of_light/(2*Range_Resolution);

%The slope of the chirp
Slope = Bandwidth/Sweep_Time


%Operating carrier frequency of Radar 
fc= 77e9;             %carrier freq

                                                          
%The number of chirps in one sequence. Its ideal to have 2^ value for the ease of running the FFT
%for Doppler Estimation. 
Nd=128;                   % #of doppler cells OR #of sent periods % number of chirps

%The number of samples on each chirp. 
Nr=1024;                  %for length of time OR # of range cells

% Timestamp for running the displacement scenario for every sample on each
% chirp
t=linspace(0,Nd*Sweep_Time,Nr*Nd); %total time for samples


%Creating the vectors for Tx, Rx and Mix based on the total samples input.
Tx=zeros(1,length(t)); %transmitted signal
Rx=zeros(1,length(t)); %received signal
Mix = zeros(1,length(t)); %beat signal

%Similar vectors for range_covered and time delay.
r_t=zeros(1,length(t));
td=zeros(1,length(t));

% Signal generation and Moving Target simulation
% Running the radar scenario over the time. 
length(t)
for i=1:length(t)         
    
    
    % *%TODO* :
    %For each time stamp update the Range of the Target for constant velocity. 
    Range(i) = R+(v*t(i));
    trip_time(i) = (2*Range(i)) / speed_of_light; 
    trip_time(i) = t(i) - trip_time(i);
    % *%TODO* :
    %For each time sample we need update the transmitted and
    %received signal. 
    Tx(i) = cos(2*pi*(frequency*t(i)+Slope*(t(i).^2)/2));
    Rx(i)  = cos(2*pi*(frequency*trip_time(i)+Slope*(trip_time(i).^2)/2));
    
    % *%TODO* :
    %Now by mixing the Transmit and Receive generate the beat signal
    %This is done by element wise matrix multiplication of Transmit and
    %Receiver Signal
    Mix(i) = Tx(i).*Rx(i);
    
end



%% RANGE MEASUREMENT


 % *%TODO* :
%reshape the vector into Nr*Nd array. Nr and Nd here would also define the size of
%Range and Doppler FFT respectively.
Mix=reshape(Mix, [Nr, Nd]);
 % *%TODO* :
%run the FFT on the beat signal along the range bins dimension (Nr) and
%normalize.
y = fft(Mix, Nr);
 % *%TODO* :
% Take the absolute value of FFT output
P2 = abs(y./Nr);
 % *%TODO* :
% Output of FFT is double sided signal, but we are interested in only one side of the spectrum.
% Hence we throw out half of the samples.
P1 = P2(1:Nr/2-1);

%plotting the range
figure ('Name','Range from First FFT')
subplot(2,1,1);

% *%TODO* :
% plot FFT output 
plot(P1);
 
axis ([0 200 0 1]);

%% RANGE DOPPLER RESPONSE
% The 2D FFT implementation is already provided here. This will run a 2DFFT
% on the mixed signal (beat signal) output and generate a range doppler
% map.You will implement CFAR on the generated RDM


% Range Doppler Map Generation.

% The output of the 2D FFT is an image that has reponse in the range and
% doppler FFT bins. So, it is important to convert the axis from bin sizes
% to range and doppler based on their Max values.

Mix=reshape(Mix,[Nr,Nd]);

% 2D FFT using the FFT size for both dimensions.
sig_fft2 = fft2(Mix,Nr,Nd);

% Taking just one side of signal from Range dimension.
sig_fft2 = sig_fft2(1:Nr/2,1:Nd);
sig_fft2 = fftshift (sig_fft2);
RDM = abs(sig_fft2);
RDM = 10*log10(RDM) ;

%use the surf function to plot the output of 2DFFT and to show axis in both
%dimensions
doppler_axis = linspace(-100,100,Nd);
range_axis = linspace(-200,200,Nr/2)*((Nr/2)/400);
figure,surf(doppler_axis,range_axis,RDM);

%% CFAR implementation

%Slide Window through the complete Range Doppler Map

% *%TODO* :
%Select the number of Training Cells in both the dimensions.
Tr = 8;
Td = 4;
% *%TODO* :
%Select the number of Guard Cells in both dimensions around the Cell under 
%test (CUT) for accurate estimation
Gr = 6; 
Gd = 3; 
% *%TODO* :
% offset the threshold by SNR value in dB
offset=1.68;
% *%TODO* :



% *%TODO* :
%design a loop such that it slides the CUT across range doppler map by
%giving margins at the edges for Training and Guard Cells.
%For every iteration sum the signal level within all the training
%cells. To sum convert the value from logarithmic to linear using db2pow
%function. Average the summed values for all of the training
%cells used. After averaging convert it back to logarithimic using pow2db.
%Further add the offset to it to determine the threshold. Next, compare the
%signal under CUT with this threshold. If the CUT level > threshold assign
%it a value of 1, else equate it to 0.


   % Use RDM[x,y] as the matrix from the output of 2D FFT for implementing
   % CFAR

RDM = RDM/max(max(RDM));
for i = Tr+Gr+1:(Nr/2)-(Gr+Tr)
       for j = Td+Gd+1:Nd-(Gd+Td)
           %Create a vector to store noise_level for each iteration on training cells
            noise_level = zeros(1,1);
            %Utilize Training Cells to measure a noise level
            for p = i-(Tr+Gr) : i+Tr+Gr
                for q = j-(Td+Gd) : j+Td+Gd
                    if(abs(i-p) > Gr || abs(j-q) > Gd)
                        noise_level = noise_level + db2pow(RDM(p,q));
                    end
                end
            end
   % Calculate the threshold using pow2db since you cannot sum without
   threshold = pow2db(noise_level/(2*(Td+Gd+1)*2*(Tr+Gr+1)-(Gr*Gd)-1));
   % Add the SNR offset to the threshold
   threshold = threshold + offset;
   %Measure the signal in Cell Under Test (CUT) and compare against
   %threshold
   CUT=RDM(i,j);
   if(CUT < threshold)
       RDM(i,j)=0;
   else 
       RDM(i,j) = 1;
   end
   end
   end


% *%TODO* :
% The process above will generate a thresholded block, which is smaller 
%than the Range Doppler Map as the CUT cannot be located at the edges of
%matrix. Hence,few cells will not be thresholded. To keep the map size same
% set those values to 0. 

for a = 1:Nr/2
    for b=1:Nd
        if (RDM(a,b) ~= 0 && RDM(a,b) ~= 1)
            RDM(a,b) = 0;
        end
    end
end






% *%TODO* :
%display the CFAR output using the Surf function like we did for Range
%Doppler Response output.
figure,surf(doppler_axis,range_axis,RDM);
colorbar;

 
