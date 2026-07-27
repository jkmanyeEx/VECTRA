function profile = loadProfile(category, profileName)
%LOADPROFILE Load a named vehicle, geometry, or experiment profile.

category = validatestring(string(category), ...
    ["vehicles", "geometries", "experiments"]);
profileName = string(profileName);

if ~endsWith(profileName, ".json")
    profileName = profileName + ".json";
end

profileFile = fullfile(vectra.root(), "config", category, profileName);
profile = vectra.config.loadJson(profileFile);
end
