function info = environment()
%ENVIRONMENT Inspect the MATLAB products required by VECTRA.

installed = ver;
installedNames = string({installed.Name});
matlabProduct = installed(installedNames == "MATLAB");

info = struct();
info.vectraVersion = vectra.version();
if isempty(matlabProduct)
    info.matlabVersion = "unknown";
else
    info.matlabVersion = string(matlabProduct.Version) + ...
        " " + string(matlabProduct.Release);
end
info.projectRoot = string(vectra.root());
info.requiredProducts = ["MATLAB", "Simulink"];
info.optionalProducts = [
    "UAV Toolbox"
    "Aerospace Toolbox"
    "Aerospace Blockset"
    "Simulink Coder"
    "Embedded Coder"
];
info.missingRequiredProducts = info.requiredProducts( ...
    ~ismember(info.requiredProducts, installedNames));
info.missingOptionalProducts = info.optionalProducts( ...
    ~ismember(info.optionalProducts, installedNames));

if nargout == 0
    fprintf("VECTRA %s\n", info.vectraVersion);
    fprintf("MATLAB %s\n", info.matlabVersion);
    fprintf("Project: %s\n", info.projectRoot);

    if isempty(info.missingRequiredProducts)
        fprintf("Required products: ready\n");
    else
        fprintf("Missing required products: %s\n", ...
            strjoin(info.missingRequiredProducts, ", "));
    end

    if isempty(info.missingOptionalProducts)
        fprintf("Optional UAV products: ready\n");
    else
        fprintf("Unavailable optional products: %s\n", ...
            strjoin(info.missingOptionalProducts, ", "));
    end
end
end
