classdef TestTelemetryLoopback < matlab.unittest.TestCase
    methods (Test)
        function receivesPyMavlinkHeartbeatOrReportsMissingRuntime(testCase)
            environment = vectra.px4.pymavlinkEnvironment();
            source = vectra.px4.LiveTelemetrySource(LocalPort=14661);
            cleanup = onCleanup(@() delete(source));

            if ~environment.ready
                testCase.verifyError(@() source.connect(), ...
                    "vectra:px4:MissingPyMavlink");
                return;
            end

            sink = TelemetryEventSink();
            source.MessageCallback = @(event)sink.capture(event);
            source.connect();
            pause(0.5);

            sender = fullfile(vectra.root(), ...
                "tests", "fixtures", "send_mavlink_heartbeat.py");
            command = quoteShell(environment.pythonExecutable) + ...
                " " + quoteShell(sender) + " --port 14661";
            [status, output] = system(command);
            testCase.verifyEqual(status, 0, output);

            pause(0.8);
            drawnow;
            testCase.verifyGreaterThanOrEqual(numel(sink.Events), 1);
            names = strings(numel(sink.Events), 1);
            for index = 1:numel(sink.Events)
                names(index) = string( ...
                    sink.Events{index}.MessageName);
            end
            testCase.verifyTrue(any(names == "HEARTBEAT"));
            testCase.verifyEqual(source.PyMavlinkVersion, ...
                environment.pymavlinkVersion);
        end
    end
end

function value = quoteShell(pathValue)
pathValue = string(pathValue);
if ispc
    value = """" + pathValue + """";
else
    value = "'" + pathValue + "'";
end
end
