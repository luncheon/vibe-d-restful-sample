## vibe.d RESTful sample

A simple web application that presents minimal usage of following frameworks.

* [vibe.d](http://vibed.org/)
* [HibernateD](https://github.com/buggins/hibernated)
* [w2ui](http://w2ui.com/) - w2grid


### Quick Start on Windows

1. Install [dmd](http://dlang.org/download.html) and [dub](http://code.dlang.org/).<br>
  Quickest way may be via [Chocolatey](https://chocolatey.org/), as following commands with administrator privileges.

 ```
@powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin

cinst dmd
cinst dub
```

2. Initialize database and start server.

 ```
cd <project-root>
dub -- initdb
dub
```
