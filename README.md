# docker-kong-oxd-server-tests
Microframework for testing Kong plugin with mock oxd-server

This git repository has some submodules, use command below to clone:

```
git clone --recursive git@github.com:altexy/docker-kong-oxd-server-tests.git
```

It uses the latest 0.14 Kong!!! 
New Service/Route objects are used and PDK framework.

Dependencies
============

The only dependency to run this test suite is docker-ce.

If you have older Docker installer - remove it (Debian based distro considered):

`sudo apt-get remove docker docker-engine docker.io`

The simplest way to install docker-ce is as below (old distros may be not supported):

`curl http://get.docker.com/ | sudo sh`


How to test
===========

```
cd docker-kong-oxd-server-tests
./t/run.sh
``` 

At the moment very basic test case `test1` is implemented.

It uses docker-compose to describe all services.

Trivial plugin which only register itself on mock oxd server is implemented.

The test case start all required services, register a Service, then Route, configure test1 plugin.

Mock oxd-server
===============

It uses mock oxd server.
The `t/test1/oxd-model.lua` defines the sequence of expected endpoints calls and responses.

