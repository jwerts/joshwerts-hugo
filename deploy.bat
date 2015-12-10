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
rem TODO add a date to commit message
git commit -m "updated site"

git push origin master

cd ..
