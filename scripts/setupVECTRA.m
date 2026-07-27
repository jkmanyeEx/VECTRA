function info = setupVECTRA()
%SETUPVECTRA Configure MATLAB paths for the current VECTRA session.

scriptDirectory = fileparts(mfilename("fullpath"));
projectRoot = fileparts(scriptDirectory);
addpath(fullfile(projectRoot, "src", "matlab"));
addpath(scriptDirectory);
addpath(fullfile(projectRoot, "tests"));

info = vectra.environment();
end
