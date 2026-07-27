function profile = loadProfile(category, profileName)
%LOADPROFILE Load a named VECTRA configuration profile.

category = validatestring(string(category), ...
    ["vehicles", "geometries", "experiments", "telemetry"]);
profileName = string(profileName);

if ~endsWith(profileName, ".json")
    profileName = profileName + ".json";
end

profileFile = fullfile(vectra.root(), "config", category, profileName);
profile = vectra.config.loadJson(profileFile);
end
