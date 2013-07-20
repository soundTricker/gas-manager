# gas-manager

> Google Apps Script Import/Export Helper for nodejs

## Getting Started
gas-manager requiered refresh-token of Google API.  
Please get refresh-token with below scopes.

* https://www.googleapis.com/auth/drive
* https://www.googleapis.com/auth/drive.file
* https://www.googleapis.com/auth/drive.scripts

If you need more detail, please refference [here](http://masashi-k.blogspot.jp/2013/07/accessing-to-my-google-drive-from-nodejs.html).

then you may install this plugin with this command:

```shell
npm install gas-manager --save
```

if you need gas-manager cli, please run below command:

```shell
npm install -g gas-manager
```

## CLI
gas-manager support Command Line Interface.

### Prepare config file.
In order to use CLI of gas-manager, it will be necessary to create config file.  
The config file default path is `./gas-config.json`.  
If you need change that, please add `-c /path/to/configfile` option when running command.  

config file should be like below.

>***Caution!*** config file inculde refresh_token, it should not publish.

```json
{
  "client_id": "your client_id , getting from Googe API Console",
  "client_secret": "your client_secret , getting from Googe API Console",
  "refresh_token":"your refresh_token, please see the adove link",
  "enviroment name": {
    "fileId" : "target Google Drive's fileId of google apps script project",
    "files" : {
      "filename on GAS Project, it should not include extension like .gs" : {
        "path" : "path/to/yourlocalfile.js",
        "type" : "file type, server_js or html"
      }
    }
  },
  "src": {
    "fileId" : "1jdu8QQcKZ5glzOaJnofi2At2Q-2PnLLKxptN0CTRVfgfz9ZIopD5sYXz",
    "files" : {
      "index.html" : {
        "path" : "src/main/view/index.html.js",
        "type" : "html"
      },
      "test2": {
        "path" : "src/main/gs/test2.js",
        "type" : "server_js"
      },
      "classes": {
        "path" : "src/main/gs/api/classes.js",
        "type" : "server_js"
      }
    }
  },
  "test": {
    "fileId" : "testfileid",
    "files" : {
      "test2Spec": {
        "path" : "src/test/gs/test2Spec.js",
        "type" : "server_js"
      },
      "classesSpec": {
        "path" : "src/test/gs/api/code.js",
        "type" : "server_js"
      }
    }
  }
}
```

### Commands

#### Show help
    $ gas --help

### Download Command
>The `download` command is downloading GAS Project to your local.

#### Show help of `download` command

    $ gas download --help

#### Download GAS Project to local.

    $ gas download -p src/main/

>***Caution!*** `gas download` command always override local sources.  
>*Note* `-p` option is default save path for downloading sources. if gas filename is not set in config, this path is used.


#### Change config file path

    $ gas download -p src/main/ -c path/to/configfile.json

>*Note* the default config file path is `./gas-config.json`.

#### Change the enviroment

    $ gas download -p src/main/ -c path/to/configfile.json -e test

>*Note* the default enviroment is `src`.

### Upload Command

>The `upload` command is uploading your local files to Google Drive's GAS Project.

#### Show help of `upload` command

    $ gas upload --help

#### Upload your local files to to Google Drive's GAS Project

    $ gas upload

>*Note* The `upload` command upload files written in config file. if file is not exist in config file, it is not uploaded.  

#### Upload your local files and delete GAS Project file, that does not exist in config file.

    $ gas upload --force

#### Change config file path

    $ gas upload -c path/to/configfile.json

>*Note* the default config file path is `./gas-config.json`.

#### Change the enviroment

    $ gas upload -e test

>*Note* the default enviroment is `src`.

## Using gas-manager as nodejs module

### Create new Project
```javascript
#!/usr/bin/env node
var Manager = require('gas-manager').Manager;
var manager = new Manager({
    'refresh_token' : 'refresh-token of OAuth2 for Google API',
    'client_id' : 'client_id of OAuth2 for Google API',
    'client_secret' : 'client_secret of OAuth2 for Google API',
});

var gasProject = manager.createProject('project name');

gasProject.addFile(
    'file name',
    'server_js', //it should be 'server_js' or 'html'
    'function test(){ Logger.log("hoge");}' //source code
).addFile(
    'index', //filename should not include extention
    'html', //it should be 'server_js' or 'html'
    '<div>Hello</div>' //source code
).deploy(
  function(err, project, response){
    if(err) {
      throw new Error(err)
    }
    //callback
  }
);

```

### Update exist Project
```javascript
#!/usr/bin/env node
var Manager = require('gas-manager').Manager;
var manager = new Manager({
    'refresh_token' : 'refresh-token of OAuth2 for Google API',
    'client_id' : 'client_id of OAuth2 for Google API',
    'client_secret' : 'client_secret of OAuth2 for Google API',
});

manager.getProject('file id at google drive', function(res, gasProject){
  var gasFile = gasProject.getFileByName("filename");
  gasFile.source +="//test";

  gasProject.addFile(
    'file name',
    'server_js', //it should be 'server_js' or 'html'
    'function test(){ Logger.log("hoge");}' //source code
  )
  //change file contents
  .changeFile("name",
    {
      name : "hoge",
      type : "html",
      source : "huga"
    }
  )
  .changeFile("name2", {source : "huga2"}) // changeFile only change setting property
  .renameFile("before filename" , "after filename")
  .deleteFile("target Filename")
  .deploy(function(err, project, response){
    if(err) {
      throw new Error(err)
    }
    //callback
  }
  );
});

```


## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Grunt](http://gruntjs.com/).

## Release History

### v0.3.0
* Add support command line interface.
    * `gas download`
    * `gas upload`

### v0.2.0
* Change interface , fit for nodejs.

### v0.1.0
* First release

## Roadmap

* Add supporting cli of creating new project like `gas create`
* Add supporting cli of generating config file like `gas init`
* Add [Grunt](http://gruntjs.com/) plugin, but it may be another repository. 

## License
Copyright (c) 2013 Keisuke Oohashi  
Licensed under the MIT license.
