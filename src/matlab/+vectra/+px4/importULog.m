function log = importULog(filename)
%IMPORTULOG Open a PX4 ULog and enumerate its available topics.

filename = string(filename);
if ~isfile(filename)
    error("vectra:px4:LogNotFound", "ULog file not found: %s", filename);
end
if exist("ulogreader", "file") ~= 2
    error("vectra:px4:MissingUAVToolbox", ...
        "ulogreader is unavailable. Install UAV Toolbox before importing " + ...
        "PX4 ULog files.");
end

reader = ulogreader(filename);
topics = readTopicMsgs(reader);

log = struct();
log.filename = filename;
log.reader = reader;
log.topics = topics;
end
