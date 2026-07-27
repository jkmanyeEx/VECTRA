function results = runAllTests()
%RUNALLTESTS Run all VECTRA unit and integration tests.

testRoot = fileparts(mfilename("fullpath"));
projectRoot = fileparts(testRoot);
addpath(fullfile(projectRoot, "src", "matlab"));
addpath(fullfile(projectRoot, "scripts"));
addpath(testRoot);

suite = testsuite(testRoot, "IncludeSubfolders", true);
results = run(suite);

if any([results.Failed])
    error("vectra:tests:Failed", "%d VECTRA tests failed.", ...
        nnz([results.Failed]));
end
end
