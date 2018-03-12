Currently Katalon team support official Docker image:
Please refere to this link https://github.com/katalon-studio/docker-images





*** Sample for research only ***
Katalon-Container:
- Pull this repository
- Run command: docker build -t katalon-container . # This will build katalon container
- Execute test suite with katalon-container: docker run --rm --name test -v /Users/minhhoang/Workspace/WorkSpace/Docker/TestSample/:/KatalonTest/ -e p="/KatalonTest/TestSample.prj" -e s="Test\ Suites/GUI" -e b=Chrome -it katalon-container 
- Link your project folder from host machine to docker container via -v /Users/minhhoang/Workspace/WorkSpace/Docker/TestSample/:/KatalonTest/
- Set container environment variable in sample command above
- List of args belows:  
 -p -- project path value   
 -s -- test suite path value   
 -r -- report path value   
 -b -- browser type value, default is firefox browser   
 -v -- enable console log mode in kataon 
