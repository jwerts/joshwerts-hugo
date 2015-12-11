@echo off
echo Deploying updates to github...

rem build the project
hugo

cd public

rem add our CNAME
echo joshwerts.com > CNAME

rem add all changes
git add -A

rem commit the changes
set mydate=!date:~10,4!!date:~6,2!/!date:~4,2!
git commit -m "updated site %mydate%"

git push origin master

cd ..
