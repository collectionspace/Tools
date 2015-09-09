# csops: UC Berkeley CollectionSpace operations scripts

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

