function commit = pinnedCommit()
%PINNEDCOMMIT Return the expected upstream QuadSim revision.

lockFile = fullfile(vectra.root(), "vendor", "quadsim-lock.json");
lock = vectra.config.loadJson(lockFile);
commit = string(lock.commit);
end
