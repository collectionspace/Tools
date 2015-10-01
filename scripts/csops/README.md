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
##### Synopsis
```
csup
```
##### Description
Starts the CollectionSpace server.

### csdown - stop CollectionSpace
##### Synopsis
```
csdown [-f]
```
##### Description
Stops the CollectionSpace server, if there is no user activity. User activity is heuristically detected using the `csidletime` program. If the idle time is sufficient, the server is stopped. Otherwise, an error is reported. The required amount of idle time may be specified in the `CS_MIN_IDLE_TIME` environment variable, as a number of seconds. If `CS_MIN_IDLE_TIME` is not set, a default of 600 seconds (10 minutes) is used.
##### Options
`-f`
	Force the server to stop, even if user activity is detected within the required idle time.

### csbounce - restart CollectionSpace
##### Synopsis
```
csbounce [-f]
```
##### Description
Restarts the CollectionSpace server, if there is no user activity. User activity is heuristically detected using the `csidletime` program. If the idle time is sufficient, the server is stopped. Otherwise, an error is reported. The required amount of idle time may be specified in the `CS_MIN_IDLE_TIME` environment variable, as a number of seconds. If `CS_MIN_IDLE_TIME` is not set, a default of 600 seconds (10 minutes) is used.
##### Options
`-f`
	Force the server to restart, even if user activity is detected within the required idle time.

### csuptime - show how long CollectionSpace has been running
##### Synopsis
```
csuptime
```
##### Description
Shows the amount of time the CollectionSpace server has been running. The time is printed to standard output, in the `etime` format used by `ps`, which is `[[dd-]hh:]mm:ss`. If CollectionSpace is not running, nothing is printed.

### csidletime - show how long CollectionSpace has been idle
##### Synopsis
```
csidletime
```
##### Description
Shows the amount of time elapsed since the last user activity in CollectionSpace. The time is printed to standard output, in seconds.  The time of last user activity is heuristically determined using log files, and therefore may not be accurate. For example, requests do not appear in certain logs until they have completed, so a long running request that is still in progress may not be detected. If no idle time can be determined (for example, if no logs exist), nothing is printed.

### csver - show the installed CollectionSpace version number
##### Synopsis
```
csver
```
##### Description
Shows the version number of the installed version of CollectionSpace. This corresponds to a tag in git. The version number is printed to standard output. This program assumes that CollectionSpace releases are created using the [`make-release`](../make-release) program, and may not work correctly if that program's conventions are not followed.

### csname - show the name of the CollectionSpace deployment
##### Synopsis
```
csname
```
##### Description
Shows the name of the CollectionSpace deployment. This is the name of the deployment's primary tenant.

### csservname - show the name of the CollectionSpace service
##### Synopsis
```
csservname
```
##### Description
Shows the name of the CollectionSpace service. This is the name of the init script, suitable for passing into the `service` program.

### csi - install CollectionSpace
##### Synopsis
```
csi [-f] [versionnumber]
```
##### Description
Installs the specified version of CollectionSpace. The version number must correspond to a tag in git. If no version number is specified, the most recently created tag that is appropriate to this deployment is used. Installation may require that the CollectionSpace server be stopped and started. If this is necessary, the `csdown` program is invoked, which will do its usual user activity check. Use the `-f` flag to force the restart even if user activity is detected.

##### Options
`-f`
	If a CollectionSpace restart is needed, force the restart, even if user activity is detected within the required idle time. Has no effect if a restart is not needed.

### cscleantemp - remove old files from the CollectionSpace server's temporary file directory
##### Synopsis
```
cscleantemp
```
##### Description
Removes old files from the CollectionSpace temporary file directory. Files with names matching the pattern `*-*-*-*-*`, and that have not been modified for some amount of time are removed. The minimum time since last modification may be specified in the `CS_TEMP_MMIN` environment variable, in minutes. If `CS_TEMP_MMIN` is not set, a default of 60 minutes (1 hour) is used.
