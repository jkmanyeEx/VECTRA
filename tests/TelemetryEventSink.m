classdef TelemetryEventSink < handle
    %TELEMETRYEVENTSINK Mutable callback sink for integration tests.

    properties
        Events cell = cell(0, 1)
    end

    methods
        function capture(this, event)
            this.Events{end + 1, 1} = event;
        end
    end
end
