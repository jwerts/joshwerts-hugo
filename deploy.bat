setlocal EnableDelayedExpansion

echo Deploying updates to github...

rem build the project
hugo

cd public

rem add our CNAME
echo joshwerts.com > CNAME

rem add all changes
git add -A

rem commit the changes
set mydate=%date:~-10,2%-%date:~7,2%-%date:~-4,4%
set message="Updated Site %mydate%"
git commit -m %message%

git push origin master

cd ..
