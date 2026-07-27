function report = validateCantImplementation(durationSec)
%VALIDATECANTIMPLEMENTATION Run the approved minimal cant verification.

arguments
    durationSec (1,1) double {mustBePositive, mustBeFinite} = 1
end

setupVECTRA();

baseline = vectra.quadsim.runBaseline("smoke_hover", durationSec);
cantZero = vectra.quadsim.runCant("cant_00", false, durationSec);
cantTen = vectra.quadsim.runCant("cant_10", false, durationSec);

baselineTime = seconds(baseline.data.Properties.RowTimes);
zeroTime = seconds(cantZero.data.Properties.RowTimes);
sameTimeGrid = numel(baselineTime) == numel(zeroTime) && ...
    max(abs(baselineTime - zeroTime)) <= 1e-9;
if sameTimeGrid
    zeroDelta = baseline.data.Variables - cantZero.data.Variables;
    zeroStateError = max(abs(zeroDelta(:, 1:12)), [], "all");
    zeroRpmError = max(abs(zeroDelta(:, 13:16)), [], "all");
    % The legacy model can expose a different algebraic output exactly at
    % StopTime when StopTime coincides with a command discontinuity. Continuous
    % state and RPM traces remain authoritative; exclude only that final
    % algebraic throttle sample.
    throttleRows = 1:max(1, height(baseline.data) - 1);
    zeroThrottleError = max( ...
        abs(zeroDelta(throttleRows, 17:20)), [], "all");
else
    zeroStateError = Inf;
    zeroRpmError = Inf;
    zeroThrottleError = Inf;
end

horizontalCoefficientSum = sum( ...
    cantTen.quadModel.wrenchMatrix(1:2, :), 2);
expectedVerticalScale = cosd(10);
actualVerticalScale = cantTen.validation.verticalForceScale;

zeroRpm = steadyMeanRpm(cantZero.data);
tenRpm = steadyMeanRpm(cantTen.data);
actualHoverRpmRatio = mean(tenRpm ./ zeroRpm);
expectedHoverRpmRatio = 1 / sqrt(expectedVerticalScale);

report = struct();
report.durationSec = durationSec;
report.zeroCant = struct( ...
    "sameTimeGrid", sameTimeGrid, ...
    "maximumStateError", zeroStateError, ...
    "maximumRpmError", zeroRpmError, ...
    "maximumThrottleErrorExceptFinalSample", zeroThrottleError, ...
    "passed", sameTimeGrid && zeroStateError <= 1e-8 && ...
        zeroRpmError <= 1e-6 && zeroThrottleError <= 1e-6);
report.tenDegree = struct( ...
    "expectedVerticalForceScale", expectedVerticalScale, ...
    "actualVerticalForceScale", actualVerticalScale, ...
    "horizontalCoefficientSumNPerRpm2", horizontalCoefficientSum, ...
    "expectedHoverRpmRatio", expectedHoverRpmRatio, ...
    "actualHoverRpmRatio", actualHoverRpmRatio, ...
    "finite", cantTen.validation.finite, ...
    "motorLimitExceeded", cantTen.validation.motorLimitExceeded, ...
    "passed", abs(actualVerticalScale - expectedVerticalScale) <= 1e-12 && ...
        norm(horizontalCoefficientSum) <= 1e-15 && ...
        actualHoverRpmRatio > 1 && ...
        abs(actualHoverRpmRatio - expectedHoverRpmRatio) <= 0.02 && ...
        cantTen.validation.finite && ...
        ~cantTen.validation.motorLimitExceeded);
report.passed = report.zeroCant.passed && report.tenDegree.passed;

if nargout == 0
    disp(report);
    if ~report.passed
        error("vectra:quadsim:CantValidationFailed", ...
            "Minimal cant implementation validation failed.");
    end
end
end

function rpm = steadyMeanRpm(data)
names = string(data.Properties.VariableNames);
rpmColumns = startsWith(names, "Motor") & endsWith(names, "_rpm");
startRow = max(1, floor(height(data) * 0.8));
rpm = mean(data{startRow:end, rpmColumns}, 1);
end
