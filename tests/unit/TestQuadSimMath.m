classdef TestQuadSimMath < matlab.unittest.TestCase
    methods (Test)
        function buildsVerticalRotorWrench(testCase)
            arm = 0.25;
            positions = [
                arm, 0, -arm, 0
                0, arm, 0, -arm
                0, 0, 0, 0
            ];
            axes = repmat([0; 0; 1], 1, 4);
            reactionTorqueSigns = [-1, 1, -1, 1];
            ct = 2.0e-7;
            cq = 3.0e-9;

            matrix = vectra.quadsim.buildWrenchMatrix( ...
                positions, axes, reactionTorqueSigns, ct, cq);

            testCase.verifySize(matrix, [6, 4]);
            testCase.verifyEqual(matrix(1:2, :), zeros(2, 4), ...
                "AbsTol", eps);
            testCase.verifyEqual(matrix(3, :), ct * ones(1, 4), ...
                "RelTol", 1e-12);
            expectedMoment = [
                0, arm * ct, 0, -arm * ct
                -arm * ct, 0, arm * ct, 0
                -cq, cq, -cq, cq
            ];
            testCase.verifyEqual(matrix(4:6, :), expectedMoment, ...
                "AbsTol", eps);
        end

        function buildsAlternatingTangentialCant(testCase)
            profile = vectra.config.loadProfile( ...
                "geometries", "cant_tangential_10");
            arm = 0.25;
            geometry = vectra.quadsim.buildRotorGeometry(profile, arm);
            ct = 2.0e-7;
            cq = 3.0e-9;
            matrix = vectra.quadsim.buildWrenchMatrix( ...
                geometry.motorPositionsBodyM, geometry.rotorAxesBody, ...
                geometry.reactionTorqueSigns, ct, cq);

            sine = sind(10);
            cosine = cosd(10);
            expectedAxes = [
                0, -sine, 0, sine
                -sine, 0, sine, 0
                cosine, cosine, cosine, cosine
            ];
            expectedYawMagnitude = arm * ct * sine + cq * cosine;

            testCase.verifyEqual( ...
                vecnorm(geometry.rotorAxesBody, 2, 1), ones(1, 4), ...
                "AbsTol", 1e-12);
            testCase.verifyEqual(geometry.rotorAxesBody, expectedAxes, ...
                "AbsTol", 1e-12);
            testCase.verifyEqual(sum(matrix(1:2, :), 2), [0; 0], ...
                "AbsTol", 1e-20);
            testCase.verifyEqual(matrix(3, :), ...
                ct * cosine * ones(1, 4), "RelTol", 1e-12);
            testCase.verifyEqual(sum(matrix(4:6, :), 2), ...
                zeros(3, 1), "AbsTol", 1e-20);
            testCase.verifyEqual(matrix(6, :), ...
                expectedYawMagnitude * [-1, 1, -1, 1], ...
                "RelTol", 1e-12);
            testCase.verifyGreaterThan( ...
                min(abs(matrix(6, :))), cq);

            allocation = vectra.quadsim.buildControlAllocation( ...
                matrix, arm);
            testCase.verifyTrue(allocation.fullRank);
        end

        function generalizedGyroMatchesLegacyAtZeroCant(testCase)
            rates = [0.4; -0.3; 0.2];
            rpm = [4100; 4200; 4300; 4400];
            axes = repmat([0; 0; 1], 1, 4);
            spin = [1, -1, 1, -1];
            jm = 1.2e-5;

            actual = vectra.quadsim.calculateGyroscopicMoment( ...
                rates, rpm, axes, spin, jm);
            P = rates(1);
            Q = rates(2);
            factor = jm * 2 * pi / 60;
            expected = [
                Q * factor * (-rpm(1) - rpm(3) + rpm(2) + rpm(4))
                P * factor * (rpm(1) + rpm(3) - rpm(2) - rpm(4))
                0
            ];

            testCase.verifyEqual(actual, expected, "AbsTol", 1e-14);
        end

        function zeroCantAllocationIsIdentity(testCase)
            active = [
                2, 2, 2, 2
                0, 1, 0, -1
                -1, 0, 1, 0
                -0.1, 0.1, -0.1, 0.1
            ];
            referenceRpm = [4000; 4100; 4200; 4300];
            allocation = vectra.quadsim.allocateMotorCommands( ...
                referenceRpm, active, active, 10000);

            testCase.verifyTrue(allocation.feasible);
            testCase.verifyEqual(allocation.commandRpm, referenceRpm, ...
                "AbsTol", 0);
            testCase.verifyEqual(allocation.residualNorm, 0, ...
                "AbsTol", 0);
        end

        function normalizesTwentyFourColumnOutput(testCase)
            tout = (0:0.1:1)';
            yout = zeros(numel(tout), 24);
            data = vectra.quadsim.normalizeOutput(yout, tout);

            testCase.verifyClass(data, "timetable");
            testCase.verifyEqual(height(data), numel(tout));
            testCase.verifyTrue(ismember("Motor4_throttle_pct", ...
                string(data.Properties.VariableNames)));
            testCase.verifyEqual(seconds(data.Properties.RowTimes(end)), 1, ...
                "AbsTol", eps);
        end
    end
end
