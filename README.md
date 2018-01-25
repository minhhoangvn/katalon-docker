To run katalon-container:
pull this repository
Run command below to build container:
- docker build -t katalon-container .
To execute test suite with katalon-container:
- docker run --rm --name test -v /Users/minhhoang/Workspace/WorkSpace/Docker/TestSample/:/KatalonTest/ -e p="/KatalonTest/TestSample.prj" -e s="Test\ Suites/GUI" -e b=Chrome -it katalon-container 
  + Link your project folder from host machine to docker container via -v /Users/minhhoang/Workspace/WorkSpace/Docker/TestSample/:/KatalonTest/
  + Set container environment variable in sample command above
-Running katalon container with list of arg variables belows:  
 -p -- project path value   
 -s -- test suite path value   
 -r -- report path value   
 -b -- browser type value, default is firefox browser   
 -v -- enable console log mode in kataon 
