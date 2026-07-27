function projectRoot = root()
%ROOT Return the absolute VECTRA project root.

persistent cachedRoot

if isempty(cachedRoot)
    thisFile = mfilename("fullpath");
    packageDirectory = fileparts(thisFile);
    matlabDirectory = fileparts(packageDirectory);
    sourceDirectory = fileparts(matlabDirectory);
    cachedRoot = fileparts(sourceDirectory);
end

projectRoot = cachedRoot;
end
