classdef TestConfiguration < matlab.unittest.TestCase
    methods (Test)
        function loadsNamedProfiles(testCase)
            vehicle = vectra.config.loadProfile("vehicles", "main_quad");
            geometry = vectra.config.loadProfile("geometries", "cant_00");
            experiment = vectra.config.loadProfile( ...
                "experiments", "smoke_hover");

            testCase.verifyEqual(string(vehicle.vehicleId), "rne-quad-01");
            testCase.verifyEqual(geometry.nominalCantAngleDeg, 0);
            testCase.verifyEqual(string(experiment.geometryProfile), ...
                "cant_00");
        end

        function resolvesRunProvenance(testCase)
            resolved = vectra.config.resolveRun( ...
                "smoke_hover", "simulation");

            testCase.verifyEqual(string(resolved.source), "simulation");
            testCase.verifyTrue(contains(string(resolved.runId), ...
                "smoke-hover-000"));
            testCase.verifyEqual(string(resolved.software.vectraVersion), ...
                vectra.version());
            testCase.verifyEqual(string(resolved.software.quadSimCommit), ...
                vectra.quadsim.pinnedCommit());
        end

        function rejectsUncalibratedResearchVehicle(testCase)
            vehicle = vectra.config.loadProfile("vehicles", "main_quad");
            testCase.verifyError( ...
                @() vectra.config.assertCalibrated(vehicle), ...
                "vectra:config:UncalibratedVehicle");
        end
    end
end
