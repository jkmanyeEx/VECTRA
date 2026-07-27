function requireVariables(data, requiredNames, context)
%REQUIREVARIABLES Require named variables in a table or timetable.

arguments
    data {mustBeA(data, ["table", "timetable"])}
    requiredNames (1,:) string
    context (1,1) string = "data"
end

available = string(data.Properties.VariableNames);
missing = requiredNames(~ismember(requiredNames, available));
if ~isempty(missing)
    error("vectra:data:MissingVariables", ...
        "%s is missing required variables: %s", ...
        context, strjoin(missing, ", "));
end
end
