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

## Examples

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
  function(response, project){
    //callback
  }
  ,function(err, response){
    //error callback, it's optional
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
  .renameFile("before filename" , "after filename")
  .deleteFile("target Filename")
  .deploy(function(res, updatedProject){
    console.log("success")
  },function(err, res){
    console.error(err, res);
  });
});

```


## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Grunt](http://gruntjs.com/).

## Release History
_(Nothing yet)_

## License
Copyright (c) 2013 Keisuke Oohashi  
Licensed under the MIT license.
