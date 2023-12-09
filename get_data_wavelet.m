
function get_data_wavelet(opts)  
% This function is used to generate spectrogram from draw audio file
% input format: file.wav 
% output format: an image with shape of nTxnF
% NOTE: + The class folders are generated automatically
%       + The file name will be renamed that is shape <class_name>_<001>.mat

%=================== Parameters for Gammatone filter Spectrogram
res_fs = 5000;
time_dur = 12;

%gam_fil_num = 128;     %Default: 128
%window_size = 0.128;    %Default: 0.025
%hop_size    = window_size/2; %Default: 0.005
min_freq    = 100;      %Default: 10
gam_opt     = 1;       %Default:1 --> Read the tool for futher explaination


r_cyc_num  = 0;
n_cyc_num  = 0;

%=================== Behavior

% 01/ Setup directory
data_txt_dir   = opts.data_txt;  
data_audio_dir = opts.data_audio;  
store_dir_R    = opts.store_dir_R;
store_dir_N    = opts.store_dir_N;



file_dir = [data_audio_dir, '/'];
file_struct = dir(file_dir);
file_name_list = {file_struct.name};  
file_name_list(strncmp(file_name_list,'.',1))=[];%remove files that start with a dot  
[nRow, file_num] = size(file_name_list);
%--------------------------------------------------------------------------------  
for nFile = 1:file_num  
    file_name = file_name_list{nFile};
    [filepath,new_file_name,ext] = fileparts(file_name);
    %new_file_name
    %pause

    %Read draw audio file
    [org_wav,fs]=audioread([file_dir, file_name_list{nFile}]); 

    %Resample 
    org_wav = resample(org_wav, res_fs, fs);
    %org_wav = bandpass(org_wav, [min_freq, res_fs/2], res_fs);
    org_wav = highpass(org_wav, min_freq, res_fs);

    limit_num = time_dur*res_fs; %10*16000

    file_txt_open = [data_txt_dir,new_file_name,'.txt'];
    %disp(file_txt_open)
    file_txt_p = fopen(file_txt_open, 'r');
    cyc_in_file = 1;
    while true
        this_line = fgetl(file_txt_p);
        if ~ischar(this_line);
            break;
        end
        C = textscan(this_line, '%f %f %f %f');
        time_st = cell2mat(C(1));
        time_ed = cell2mat(C(2));
        is_r3    = cell2mat(C(3));
        is_r4    = cell2mat(C(4));
        id_st   = int64(time_st*res_fs) + 1;
        id_ed   = int64(time_ed*res_fs);
        data = org_wav(id_st:id_ed); 
     
        %Solve issue of data length
        org_cyc_length = id_ed - id_st;
        new_data = data;
        if(org_cyc_length < limit_num);  %10*16000
            while(1);
                new_data = [new_data; data];
                [new_data_len, col] = size(new_data);
                if(new_data_len >= limit_num);
                    new_data = new_data(1:limit_num);
                    break
                end
            end
        else
            %new_data = new_data(0:limit_num);
            new_data = new_data(1:limit_num);
        end
        
        %Convert into spectrogram
        new_data = new_data + eps;
       
        %D  = cwt(new_data, 'bump',res_fs);
        D  = cwt(new_data, 'morse',res_fs);
        %D  = cwt(new_data, 'amor',res_fs);
        wt = abs(D);
        [row, col] = size(wt);
        %pause

        if(col ~= limit_num);
            fprintf('ERROR Col dimenssion at file %s: %d, %d \n', file_name, row, col);
            pause
        end

        %Scale into 124x155
        clear data1;
        nX = 256; %256
        for x=1:nX
            max_id = ceil(col/nX*x);
            if(max_id > col);
                max_id = col;
            end
            data1(:, x) = mean(wt(:, ceil(col/nX*(x-1))+1 : max_id), 2);
        end
        
        %clear data2;
        %nY = 128;
        %for y=1:nY
        %    max_id = ceil(row/nY*y);
        %    if(max_id > row);
        %        max_id = row;
        %    end
        %    data2(y,:)=mean(data1(ceil(row/nY*(y-1))+1:max_id,:));
        %end
        data2 = data1;
        size(data2)
        %pause

         %File save 
         if(is_r4);
             file_save = [store_dir_R, '01_R_', new_file_name, '_R_',  num2str(cyc_in_file), '.mat']; 
             r_cyc_num = r_cyc_num + 1;
         else
             file_save = [store_dir_N, '01_N_', new_file_name, '_N_', num2str(cyc_in_file), '.mat']; 
             n_cyc_num = n_cyc_num + 1;
         end

         clear final_data;
         final_data = data2;
         %size(final_data)
         %pause

         save(file_save, 'final_data');  
         cyc_in_file = cyc_in_file + 1;
         %pause

    end %end while

end % end of all files

fprintf('======================= Done extracting \n');  


r_cyc_num  
n_cyc_num  


r_cyc_num + n_cyc_num
end %function  
