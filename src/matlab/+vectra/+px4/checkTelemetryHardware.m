function report = checkTelemetryHardware(localPort)
%CHECKTELEMETRYHARDWARE Inspect passive telemetry prerequisites.

arguments
    localPort (1,1) double {mustBeInteger, mustBePositive} = 14551
end

report = struct();
report.checkedAtUtc = string(datetime("now", ...
    TimeZone="UTC", ...
    Format="yyyy-MM-dd'T'HH:mm:ss.SSSXXX"));
report.localPort = localPort;
python = vectra.px4.pymavlinkEnvironment();
report.pythonAvailable = python.pythonAvailable;
report.bridgeAvailable = python.bridgeAvailable;
report.pymavlinkAvailable = python.pymavlinkAvailable;
report.pymavlinkVersion = python.pymavlinkVersion;
report.pythonExecutable = python.pythonExecutable;
report.usbSerialPorts = findUsbSerialPorts();
report.usbSerialDetected = ~isempty(report.usbSerialPorts);
report.localPortAvailable = canBindUdpPort(localPort);

issues = strings(0, 1);
if ~report.pythonAvailable
    issues(end + 1, 1) = ...
        "Project Python environment is missing.";
elseif ~report.pymavlinkAvailable
    issues(end + 1, 1) = ...
        "PyMAVLink is not installed in the project environment.";
end
if ~report.usbSerialDetected
    issues(end + 1, 1) = ...
        "No USB serial telemetry adapter is visible to macOS.";
end
if ~report.localPortAvailable
    issues(end + 1, 1) = sprintf( ...
        "UDP port %d is already in use.", localPort);
end
report.issues = issues;
report.ready = report.pymavlinkAvailable && ...
    report.localPortAvailable;
end

function ports = findUsbSerialPorts()
entries = [dir("/dev/cu.usb*"); dir("/dev/cu.SLAB*")];
if isempty(entries)
    ports = strings(0, 1);
else
    ports = unique("/dev/" + string({entries.name})');
end
end

function available = canBindUdpPort(port)
socket = [];
try
    address = java.net.InetSocketAddress("0.0.0.0", port);
    socket = java.net.DatagramSocket([]);
    socket.setReuseAddress(false);
    socket.bind(address);
    available = true;
catch
    available = false;
end
if ~isempty(socket)
    try
        socket.close();
    catch
    end
end
end
