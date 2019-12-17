# Radar Target Generation and Detection

### Implementation steps for the 2D CFAR process.
* Determine the number of Training cells for each dimension. Similarly, pick the number of guard cells.
* Slide the cell under test across the complete matrix. Make sure the CUT has margin for Training and Guard cells from the edges.
* For every iteration sum the signal level within all the training cells. To sum convert the value from logarithmic to linear using db2pow function.
* Average the summed values for all of the training cells used. After averaging convert it back to logarithmic using pow2db.
* Further add the offset to it to determine the threshold.
* Next, compare the signal under CUT against this threshold.
* If the CUT level > threshold assign it a value of 1, else equate it to 0.

```c++
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
```


### Selection of Training, Guard cells and offset.
By playing around with the values and understanding the different dimensions (range and doppler) we get the following:

```c++
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
```
### Steps taken to suppress the non-thresholded cells at the edges.
To suppress the non-thresholded cells at the edges we have to iterate through the dimensions.
```c++

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
```


