load 'julia2matlab2hypre_matrix.mat'
% hardcoded vector file name, 
% must load
%   sparse matrix with name A
%   string with name output_filename
%   integer with name num_procs

filename = output_filename;

% Error handling.
if ~issparse(A)
       error('BLOPEX:matlab2hypreIJ:MatrixNotSparse','%s',...
           'Input matrix must be sparse format.')
end

[m, n] = size(A);
if m ~= n
    error('BLOPEX:matlab2hypreIJ:MatrixNotSquare','%s',...
        'Input matrix must be a square matrix.')
end

if ~ischar(filename)
    error('BLOPEX:matlab2hypreIJ:InvalidFilename','%s',...
        'Filename must be a string.')
end

precision = '16.15e';
prt_format = strcat('%d %d %', precision, '\n');



[hypre_data(:,1), hypre_data(:,2), hypre_data(:,3)] = find(A);
hypre_data = sortrows(hypre_data);
nrows = size(hypre_data,1);
hypre_data(:,1:2) = hypre_data(:,1:2) - 1;

% generate partitioning across processes
% See Hypre getpart.c
part_size = floor(n/num_procs);
rest = mod(n, num_procs);
part = [0 (rest + part_size):part_size:n];

% generate Hypre input files
s0='00000';
index=1;
for i = 1:num_procs
    
    % generate filename suffix and full filename.
    s1 = int2str(i-1);
    ls = length(s1);   
    filename2 = [filename, '.', s0(1:(5-ls)), s1];
    fprintf('Generating file: %s\n', filename2);
    fid = fopen(filename2,'w');

    
    % find indices of rows contained in partition i.
    index1 = index;
    index = index + floor(nrows/num_procs);
    index = min(index, nrows);
    while hypre_data(index,1) >= part(i + 1)
        index = index - 1;
    end
    while (index <= nrows) && (hypre_data(index,1) < part(i + 1))
        index = index + 1;
    end
    index2 = index - 1;
    
    fprintf(fid,'%d %d %d %d\n',part(i),part(i+1)-1,part(i),part(i+1)-1);
    fprintf(fid,prt_format, hypre_data(index1:index2,:)');
    fclose(fid);
end
exit