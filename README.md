## vibe.d RESTful sample

for my study.


### Quick Start on Windows

* Install [dmd](http://dlang.org/download.html) and [dub](http://code.dlang.org/).
  Quickest way may be via [Chocolatey](https://chocolatey.org/), as following commands with administrator privileges.

```
@powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin

cinst dmd
cinst dub
```

* Start server.

```
cd <project-root>
dub
```


### See Also

* [vibe.d](http://vibed.org/)
* [w2ui](http://w2ui.com/)
