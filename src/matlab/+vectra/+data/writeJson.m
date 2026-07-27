function writeJson(filename, value)
%WRITEJSON Write a MATLAB value as indented UTF-8 JSON.

filename = string(filename);
parentDirectory = fileparts(filename);
if strlength(parentDirectory) > 0 && ~isfolder(parentDirectory)
    mkdir(parentDirectory);
end

encoded = jsonencode(value, "PrettyPrint", true);
fileId = fopen(filename, "w", "n", "UTF-8");
if fileId < 0
    error("vectra:data:CannotOpenFile", ...
        "Cannot open JSON file for writing: %s", filename);
end

cleanup = onCleanup(@() fclose(fileId));
count = fwrite(fileId, encoded, "char");
if count ~= strlength(string(encoded))
    error("vectra:data:IncompleteWrite", ...
        "JSON write was incomplete: %s", filename);
end
fwrite(fileId, newline, "char");
end
