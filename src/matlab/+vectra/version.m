function value = version()
%VERSION Return the VECTRA semantic version string.

versionFile = fullfile(vectra.root(), "VERSION");
value = string(strtrim(fileread(versionFile)));
end
