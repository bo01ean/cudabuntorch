docker stop $(docker ps -a -q);
docker rm $(docker ps -a -q);
docker run -it -v`pwd`:/tmp  ubuntu:16.04
#### Run this in docker
### /tmp/test.sh
