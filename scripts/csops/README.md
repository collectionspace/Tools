# csops - operations scripts for UCB-CSpace

This is a suite of scripts for operating CollectionSpace on UC Berkeley's managed RHEL server environment.

## Installation

Each application owner (e.g. `app_pahma`) should install the scripts.

Clone this repository:

```
cd ~/src/cspace-deployment
git clone https://github.com/cspace-deployment/Tools.git
```

Link the `cs*` executables into the user's `bin` directory:

```
cd ~/bin
ln -s ~/src/cspace-deployment/Tools/scripts/csops/cs* .
```

## Usage

### csup - start CollectionSpace
TK

### csdown - stop CollectionSpace
TK

### csbounce - restart CollectionSpace
TK

### csuptime - show how long CollectionSpace has been running
TK

### csidletime - show how long CollectionSpace has been idle
TK

### csver - show the installed CollectionSpace version number
TK

### csname - show the name of the CollectionSpace deployment
TK

### csservname - show the name of the CollectionSpace service
TK

### csi - install CollectionSpace
TK

### cscleantemp - remove old files from the CollectionSpace server's temporary file directory
TK
