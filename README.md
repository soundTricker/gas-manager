# gas-manager

> Google Apps Script Import/Export Helper for nodejs

## Install

you may install this plugin with this command:

```shell
npm install gas-manager --save
```

if you need gas-manager cli, please run below command:

```shell
npm install -g gas-manager
```

## Getting Started

gas-manager requiered refresh-token of Google API.  
Please get refresh-token with below scopes.

* https://www.googleapis.com/auth/drive
* https://www.googleapis.com/auth/drive.file
* https://www.googleapis.com/auth/drive.scripts

gas-manager provide generator of the refresh-token.  
Please run with this command:

```shell
gas init
```

Or if you need get it yourown, please refference [here](http://masashi-k.blogspot.jp/2013/07/accessing-to-my-google-drive-from-nodejs.html).

then 

## CLI
gas-manager support Command Line Interface.

### Prepare credential file.
In order to use CLI of gas-manager, it will be necessary to create credential and project-setting file.  

You can create these files by running this command

```shell
gas init
```

#### Credential File

The credential file　retain Google OAuth2 properties, thease are client id, client secret and refresh token.
that default path is `{USER_HOME}/gas-credential.json`.  
If you need change that, please add `-c /path/to/credentialfile` option when running command.  

gas-manager need this file each your account.

Then credential file should be like below.

>***Caution!*** credential file inculde refresh_token, it should not publish.

```json
{
  "client_id": "your client_id , getting from Googe API Console",
  "client_secret": "your client_secret , getting from Googe API Console",
  "refresh_token":"your refresh_token, please see the adove link",
}
```

#### Project Setting File

The project-setting file retain gas project settings, thease are source mapping between gas project and your local file, gas project fileId.  
that default path is `./gas-project.json`.
If you need change that, please add `-s /path/to/project-settingfile` option when running command.  

If you do not need create this file, please add `-S "gas-project-filename:/path/to/yourlocalfile ..."` option like below.

```shell
gas upload -f {gas-project fileId} -S "code:./src/main/js/code.js index:./src/main/view/index.html"
```

Then credential file should be like below.

```json
{
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

### Init Command
> THe `init` command generate credential file and project-setting file with interactive interface.

#### Make credential and project-setting files.

    $ gas init

#### Make a only project-setting file.

    $ gas init -P

### Download Command
>The `download` command is downloading GAS Project to your local.

#### Show help of `download` command

    $ gas download --help

#### Download GAS Project to local.

    $ gas download

>***Caution!*** `gas download` command always override local sources.  
>*Note* `-p` option is default save path for downloading sources. if gas filename is not set in credential, this path is used.

#### Change the credential file path

    $ gas download -p src/main/ -c /path/to/credentialfile.json

>*Note* the default credential file path is `./gas-credential.json`.

#### Change the project file path

    $ gas download -s /path/to/projectsettingfilepath

#### Change the enviroment

    $ gas download -p src/main/ -c /path/to/credentialfile.json -e test

>*Note* the default enviroment is `src`.

#### Download files without project file

    $ gas download -S "code:/path/to/localfile index:/path/to/localfile"

#### Force download

    $ gas download --force

>*Note* the `--force` option is downloading files if a server file is not defined at the project setting file.  
that download to current directory. if you need change this path, please use `-p /path/to/basepath` option.

### Upload Command

>The `upload` command is uploading your local files to Google Drive's GAS Project.

#### Show help of `upload` command

    $ gas upload --help

#### Upload your local files to to Google Drive's GAS Project

    $ gas upload

>*Note* The `upload` command upload files written in credential file. if file is not exist in credential file, it is not uploaded.  

#### Upload files without project file

    $ gas upload -S "code:/path/to/localfile index:/path/to/localfile"

#### Upload your local files and delete GAS Project file, that does not exist in credential file.

    $ gas upload --force

#### Change credential file path

    $ gas upload -c path/to/credentialfile.json

>*Note* the default credential file path is `./gas-credential.json`.

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

### v0.4.0
* Add `init` command
* Divide config file to credential file and project-setting file.
* Add `--src` option for running with out project-setting file.

### v0.3.1
* Fix critical bug.
    * Fixed that the `gas upload` command write wrong file.

### v0.3.0
* Add support command line interface.
    * `gas download`
    * `gas upload`

### v0.2.0
* Change interface , fit for nodejs.

### v0.1.0
* First release

## Roadmap

* Add supporting crypting credential file.
* Add supporting cli of creating new project like `gas create`
* Add [Grunt](http://gruntjs.com/) plugin, but it may be another repository. 

## License
Copyright (c) 2013 Keisuke Oohashi  
Licensed under the MIT license.
