function report = runCantValidationLogged()
%RUNCANTVALIDATIONLOGGED Rebuild, test, and log the Cant MVP validation.

setupVECTRA();
logDirectory = fullfile(vectra.root(), "results", "reports", ...
    "cant-validation");
if ~isfolder(logDirectory)
    mkdir(logDirectory);
end
logFile = fullfile(logDirectory, "console.log");

diary off
diary(logFile)
diaryCleanup = onCleanup(@() diary("off"));

fprintf("VECTRA_CANT_VALIDATION_START=%s\n", ...
    string(datetime("now")));
try
    previousFileGeneration = Simulink.fileGenControl("getConfig");
    cacheRoot = fullfile(vectra.root(), "models", "generated", ...
        "cant-validation-" + string(datetime("now", ...
        "Format", "yyyyMMdd-HHmmss")));
    cacheFolder = fullfile(cacheRoot, "cache");
    codeGenerationFolder = fullfile(cacheRoot, "codegen");
    Simulink.fileGenControl("set", ...
        "CacheFolder", cacheFolder, ...
        "CodeGenFolder", codeGenerationFolder, ...
        "keepPreviousPath", false, ...
        "createDir", true);
    fileGenerationCleanup = onCleanup(@() ...
        restoreFileGeneration(previousFileGeneration));
    fprintf("SIMULINK_CACHE_FOLDER=%s\n", cacheFolder);
    fprintf("SIMULINK_SDI_REPOSITORY=%s\n", ...
        string(Simulink.sdi.getSource()));

    vectra.quadsim.setupPaths();
    modelReport = configureCantModel();
    disp(modelReport);

    unitResults = runAllTests();
    fprintf("UNIT_PASSED=%d UNIT_FAILED=%d\n", ...
        nnz([unitResults.Passed]), nnz([unitResults.Failed]));

    fprintf("CANT_INTEGRATION_VALIDATION_START\n");
    report = validateCantImplementation(1);
    disp(report);
    fprintf("CANT_VALIDATION_PASSED=%d\n", report.passed);
    if ~report.passed
        error("vectra:quadsim:CantValidationFailed", ...
            "Cant validation report did not pass.");
    end

    vectra.data.writeJson(fullfile(logDirectory, ...
        "validation-report.json"), report);
    fprintf("VECTRA_CANT_VALIDATION_COMPLETE=%s\n", ...
        string(datetime("now")));
catch validationError
    fprintf("VECTRA_CANT_VALIDATION_ERROR\n");
    disp(getReport(validationError, "extended"));
    if isDmrDiskError(validationError)
        fprintf("VECTRA_DMR_SESSION_RECOVERY_REQUIRED\n");
        fprintf(["The Simulink logging repository for this MATLAB " ...
            "session is unavailable.\n"]);
        fprintf(["Fully quit MATLAB, reopen it in the VECTRA root, " ...
            "then rerun startup.m and runCantValidationLogged().\n"]);
    end
    rethrow(validationError);
end

clear fileGenerationCleanup
clear diaryCleanup
end

function restoreFileGeneration(previousConfiguration)
Simulink.fileGenControl("setConfig", ...
    "config", previousConfiguration, ...
    "keepPreviousPath", false, ...
    "createDir", true);
end

function tf = isDmrDiskError(validationError)
message = string(validationError.message);
tf = contains(message, ".dmr", "IgnoreCase", true) && ...
    contains(message, "disk I/O error", "IgnoreCase", true);
end
