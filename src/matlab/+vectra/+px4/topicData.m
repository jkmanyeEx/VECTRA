function data = topicData(log, topicName)
%TOPICDATA Extract one named PX4 topic from imported ULog metadata.

arguments
    log struct
    topicName (1,1) string
end

if ~isfield(log, "topics")
    error("vectra:px4:InvalidImportedLog", ...
        "Imported log does not contain topic metadata.");
end

topics = log.topics;
if istable(topics)
    names = string(topics.TopicNames);
    matching = names == topicName;
    if ~any(matching)
        error("vectra:px4:TopicNotFound", ...
            "PX4 topic not found: %s", topicName);
    end
    data = topics.TopicMessages{find(matching, 1, "first")};
elseif isstruct(topics) && isfield(topics, char(topicName))
    data = topics.(char(topicName));
else
    error("vectra:px4:UnsupportedTopicContainer", ...
        "Unsupported topic container returned by UAV Toolbox.");
end
end
