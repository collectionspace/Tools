# node-cspace-scripts

Node.js scripts for UC Berkeley CollectionSpace deployments. These scripts use the [collectionspace.js](https://github.com/ray-lee/collectionspace.js) library to perform operations on CollectionSpace records.

# Installation

Install [Node.js](https://nodejs.org/) and [npm](https://www.npmjs.com/). 

Clone the [cspace-deployment/Tools](https://github.com/cspace-deployment/Tools) repository. In this example, the Tools repository will be placed in a directory named `CollectionSpace`.

```
cd CollectionSpace
git clone https://github.com/cspace-deployment/Tools.git
```

Install the required dependencies from npm. This downloads all the necessary packages except for the collectionspace package.

```
cd Tools/node-cspace-scripts
npm install
```

Unlike the other dependencies, the collectionspace package is not yet available on npm, so it must be downloaded from github, and linked into `node-cspace-scripts`.

```
cd ../..
git clone https://github.com/ray-lee/collectionspace.js
cd collectionspace.js
sudo npm link
cd ../Tools/node-cspace-scripts
npm link collectionspace
```

Optional, but helpful: Install the [Bunyan](https://github.com/trentm/node-bunyan) [CLI](http://trentm.com/node-bunyan/bunyan.1.html) for displaying logs.

```
sudo npm install -g bunyan
```
# Executing a Script

Scripts reside under the scripts directory. Execute a script using the Node.js executable, for example:

```
node scripts/PAHMA-1353/createComponents.js
```

These scripts print logs to standard output. Use shell redirects to save logs to a file, for example:

```
node scripts/PAHMA-1353/createComponents.js &> createComponents.log.json
```

Logs are printed in JSON format so that they may be processed easily by other programs. Use bunyan to print logs in a more human-friendly format, for example:

```
bunyan -L -o short createComponents.log.json
```

or:

```
tail -f createComponents.log.json | bunyan -L -o short
```

