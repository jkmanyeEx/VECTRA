projectRoot = fileparts(mfilename("fullpath"));
addpath(fullfile(projectRoot, "src", "matlab"));
addpath(fullfile(projectRoot, "scripts"));
addpath(fullfile(projectRoot, "tests"));

fprintf("VECTRA %s ready at %s\n", ...
    strtrim(fileread(fullfile(projectRoot, "VERSION"))), projectRoot);
clear projectRoot
