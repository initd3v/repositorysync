# repositorysync.sh

## Table of contents
* [Description](#description)
* [Dependencies](#dependencies)
* [Setup](#setup)
* [Usage](#usage)

## Description
The script 'repositorysync.sh' is used for syncing repository data on different sources to a local storage medium. Additionally it can be used for uploading the information later to a remote storage.

To run the script you need to configure a configuration file. Further information can be obtained from the 'Usage' part.

Supported repository sources:

* oracle repository sources
* debian repository sources
* Proxmox repository sources (including Enterprise repositories)
* Git repository sources
* single file ressources for non-redundant download
* single folder ressources for redundant download

The Project is written as a GNU bash shell script.

## Dependencies

| Dependency            | Version                               | Necessity     | Used Command Binary                                                                               |
|:----------------------|:--------------------------------------|:-------------:|:-------------------------------------------------------------------------------------------------:|
| bc                    | >= 1.07.1                             | necessary     | bc                                                                                                |
| dnf                   | >= 4.14.0                             | optional      | dnf                                                                                               |
| ftpsync               | >= 20180513                           | optional      | ftpsync                                                                                           |
| GNU bash              | >= 5.1.4(1)                           | necessary     | bash                                                                                              |
| GNU Awk               | >= 5.1.0                              | necessary     | awk                                                                                               |
| GNU Coreutils         | >= 8.32c                              | necessary     | clear & cat & cp & date & dirname & echo & false & ln & mkdir & realpath & rm & test & true       |
| git                   | >= 2.30.2                             | optional      | git                                                                                               |
| gpg                   | >= 2.2.40                             | necessary     | gpg                                                                                               |
| grep                  | >= 3.6                                | necessary     | grep                                                                                              |
| proxmox-offline-mirror| >= 2.30.2                             | optional      | proxmox-offline-mirror                                                                            |
| sed                   | >= 4.9                                | necessary     | sed                                                                                               |
| wget                  | >= 1.21                               | necessary     | wget                                                                                              |
| whereis               | >= 2.36.1                             | necessary     | whereis                                                                                           |

## Setup
To run this project, you need to clone it to your local computer and run it as a shell script.

```
$ cd /tmp
$ git clone https://github.com/initd3v/repositorysync.git
```
## Usage

### Running the script

To run this project, you must add the execution flag for the user context to the bash file. Afterwards execute it in a bash shell. 
After every successful execution the current option configuration will be saved in the download directory.
The log file is located in the download directory.

```
$ chmod u+x /tmp/repositorysync/src/repositorysync.sh
$ /tmp/linux_monitor/src/monitor.sh [--help | help | -h] [--download | download | -download] [--version | version | -v]
```

### Syntax

#### Syntax Overview

* monitor.sh [--help | help | -h]
* monitor.sh [--download | download | -d]
* monitor.sh [--version | version | -v]

#### Syntax Description

The folowing syntax options are valid.

| Option syntax                 | Description                               | Necessity | Supported value(s)  | Default |
|:------------------------------|:------------------------------------------|:---------:|:-------------------:|:-------:|
| --help \| help \| -h          | display help information                  | optional  | -                   | -       |
| --download \| download \| -d  | start sync process                        | optional  | -                   | -       |
| --version \| version \| -h    | display version information               | optional  | -                   | -       |

### Configuration

The configuration file needs to be placed / linked in the same folder as the main script and has to be named 'repositorysync.conf'.

An example configuration can be found in the cloned repository at file 'repositorysync.conf.example'

#### Configuration Description

The folowing configuration options are valid.

| Variable                          | Description                                                                                                         | Example                                                   |Necessity  | Supported value(s)                                                                |Entry Separator  |Value Separator  | Default |
|:----------------------------------|:--------------------------------------------------------------------------------------------------------------------|:----------------------------------------------------------|:---------:|:---------------------------------------------------------------------------------:|:---------------:|:---------------:|:-------:|
| REPO_DOWNLOAD_BASEPATH            | defines the local base path where the repositories and logs are stored                                              | REPO_DOWNLOAD_BASEPATH="/mnt/extern"                      | necessary | STRING                                                                            |                 |                 |         |
| REPO_DOWNLOAD_ARCH_INCLUDE        | defines the CPU architectures which should be included (not each repository download supports all CPU architectures)| REPO_DOWNLOAD_ARCH_INCLUDE="amd64|i386|armhf|armel|arm64" | optional  | amd64,i386,armhf,armel,arm64,arc,mips,mipsel,mips64el,ppc64el,s390x,riscv64,source| \|              |                 |         |
| REPO_DOWNLOAD_DEBIAN              | enables the Debian repository sync (ensure that variable REPO_DOWNLOAD_DEBIAN_REPOSITORIES is defined)              | REPO_DOWNLOAD_DEBIAN=1                                    | optional  | 0,1                                                                               |                 |                 |         |
| REPO_DOWNLOAD_DEBIAN_EXCLUDE      | sets the Debian exclude pattern filter for the rsync binary                                                         | REPO_DOWNLOAD_DEBIAN_EXCLUDE="--exclude=experimental*"    | optional  | STRING                                                                            |                 |                 |         |
| REPO_DOWNLOAD_DEBIAN_REPOSITORIES | defines the single repository parameters for the Debian sync - each entry is divided  by a pipe (\|)                | [^1]                                                      | optional  | [^1]                                                                              | \|              | :::             |         |
| REPO_DOWNLOAD_ORACLE              | enables the Oracle repository sync (ensure that variable REPO_DOWNLOAD_ORACLE_REPOSITORIES is defined)              | REPO_DOWNLOAD_ORACLE=1                                    | optional  | 0,1                                                                               |                 |                 |         |
| REPO_DOWNLOAD_ORACLE_REPOSITORIES | defines the single repository parameters for the Oracle sync - each entry is divided  by a pipe (\|)                | [^2]                                                      | optional  | [^2]                                                                              | \|              | :::             |         |
| REPO_DOWNLOAD_PROXMOX             | enables the Proxmox repository sync (ensure that variable REPO_DOWNLOAD_PROXMOX_REPOSITORIES is defined)            | REPO_DOWNLOAD_PROXMOX=1                                   | optional  | 0,1                                                                               |                 |                 |         |
| REPO_DOWNLOAD_PROXMOX_ENTERPRISE  | defines the necessary keys and service ID to permit Proxmox enterprise repository synchronisation                   | [^3]                                                      | optional  | [^3]                                                                              | \|              | :::             |         |
| REPO_DOWNLOAD_PROXMOX_REPOSITORIES| defines the single repository parameters for the Proxmox sync - each entry is divided  by a pipe (\|)               | [^4]                                                      | optional  | [^4]                                                                              | \|              | :::             |         |
| REPO_DOWNLOAD_GIT                 | enables the GIT repository sync (ensure that variable REPO_DOWNLOAD_GIT_REPOSITORIES is defined)                    | REPO_DOWNLOAD_GIT=1                                       | optional  | 0,1                                                                               |                 |                 |         |
| REPO_DOWNLOAD_GIT_REPOSITORIES    | defines the single repository parameters for the GIT sync - each entry is divided  by a pipe (\|)                   | [^5]                                                      | optional  | [^5]                                                                              | \|              | :::             |         |
| REPO_DOWNLOAD_OTHER               | enables the other repository sync (ensure that variable REPO_DOWNLOAD_OTHER_REPOSITORIES is defined)                | REPO_DOWNLOAD_OTHER=1                                     | optional  | 0,1                                                                               |                 |                 |         |
| REPO_DOWNLOAD_OTHER_REPOSITORIES  | defines the single repository parameters for the other sync - each entry is divided  by a pipe (\|)                 | [^6]                                                      | optional  | [^6]                                                                              | \|              | :::             |         |

[^1] Value Description vaiable 'REPO_DOWNLOAD_DEBIAN_REPOSITORIES'
* SOURCE_URI            : source domain URI without "http://" / "https://"
* SOURCE_REPO           : sub path of URI
* TARGET_PATH           : local folder name which the local files are synced to (<REPO_DOWNLOAD_BASEPATH>/debian/<TARGET_PATH>)

* entry                 : REPO_DOWNLOAD_DEBIAN_REPOSITORIES="[SOURCE_URI]:::[SOURCE_REPO]:::[TARGET_PATH]"

                        REPO_DOWNLOAD_DEBIAN_REPOSITORIES="ftp.de.debian.org:::debian-security:::debian-security"
                      
or

* first entry           : REPO_DOWNLOAD_DEBIAN_REPOSITORIES="[SOURCE_URI]:::[SOURCE_REPO]:::[TARGET_PATH]"
* additional entry      : REPO_DOWNLOAD_DEBIAN_REPOSITORIES+="|[SOURCE_URI]:::[SOURCE_REPO]:::[TARGET_PATH]"

                        REPO_DOWNLOAD_DEBIAN_REPOSITORIES="ftp.de.debian.org:::debian-security:::debian-security"
                        REPO_DOWNLOAD_DEBIAN_REPOSITORIES+="|ftp.de.debian.org:::debian:::debian"

[^2] Value Description vaiable 'REPO_DOWNLOAD_ORACLE_REPOSITORIES'
* ID                    : ID to which will the repository will be saved to ("<REPO_DOWNLOAD_BASEPATH>/oracle/OL<SOURCE_VERSION>/<ID>")
* DESCRIPTION           : repository description which will be written to the name field of the temporary configuration file
* SOURCE_URI            : source URI which will be used for the syncronisation
* SOURCE_VERSION        : Oracle Linux version which it is used for (necessary to create the sub folder)

* entry                 : REPO_DOWNLOAD_ORACLE_REPOSITORIES="[ID]:::[DESCRIPTION]:::[SOURCE_URI]:::[SOURCE_VERSION]"

                        REPO_DOWNLOAD_ORACLE_REPOSITORIES="ol9_baseos_latest_x86_64:::Oracle Linux 9 (x86_64) BaseOS Latest:::https://yum.oracle.com/repo/OracleLinux/OL9/baseos/latest/x86_64:::9"

or

* first entry           : REPO_DOWNLOAD_ORACLE_REPOSITORIES="[ID]:::[DESCRIPTION]:::[SOURCE_URI]:::[SOURCE_VERSION]"
* additional entry      : REPO_DOWNLOAD_ORACLE_REPOSITORIES+="|[ID]:::[DESCRIPTION]:::[SOURCE_URI]:::[SOURCE_VERSION]"

                        REPO_DOWNLOAD_ORACLE_REPOSITORIES="ol9_baseos_latest_x86_64:::Oracle Linux 9 (x86_64) BaseOS Latest:::https://yum.oracle.com/repo/OracleLinux/OL9/baseos/latest/x86_64:::9"
                        REPO_DOWNLOAD_ORACLE_REPOSITORIES+="|ol9_baseos_latest_aarch64:::Oracle Linux 9 (aarch64) BaseOS Latest:::https://yum.oracle.com/repo/OracleLinux/OL9/baseos/latest/aarch64:::9"

[^3] Value Description vaiable 'REPO_DOWNLOAD_PROXMOX_ENTERPRISE'
* POM_KEY               : Proxmox Offline Mirror Client key (can be ordered freely after purchasing a premium license - https://pom.proxmox.com/offline-keys.html#setup-offline-mirror-key)
* PREMIUM_KEY           : Proxmox Premium Key for PVE / PBS...
* PREMIUM_KEY_SERVER_ID : server ID to which the Proxmox Premium Key is assigned (https://pom.proxmox.com/offline-keys.html#setup-offline-mirror-key)

* entry                 : REPO_DOWNLOAD_PROXMOX_ENTERPRISE="[POM_KEY]:::[PREMIUM_KEY]:::[PREMIUM_KEY_SERVER_ID]"

                        REPO_DOWNLOAD_PROXMOX_ENTERPRISE="pom-1234abcdef:::pve2p-12abc3d4e5:::0AB1C345D67EFFF899F9F99FFFFF9F9"

or

* first entry           : REPO_DOWNLOAD_PROXMOX_ENTERPRISE="[POM_KEY]:::[PREMIUM_KEY]:::[PREMIUM_KEY_SERVER_ID]"
* additional entry      : REPO_DOWNLOAD_PROXMOX_ENTERPRISE+="|[POM_KEY]:::[PREMIUM_KEY]:::[PREMIUM_KEY_SERVER_ID]"

                        REPO_DOWNLOAD_PROXMOX_ENTERPRISE="pom-1234abcdef:::pve2p-12abc3d4e5:::0AB1C345D67EFFF899F9F99FFFFF9F9"
                        REPO_DOWNLOAD_PROXMOX_ENTERPRISE+="|pom-1234abcdef:::pve2p-12abc3d4e5:::0AB1C345D67EFFF899F9F99FFFFF9F9"

[^4] Value Description vaiable 'REPO_DOWNLOAD_PROXMOX_REPOSITORIES'
* SOURCE_URI            : source URI which will be used for the syncronisation
* RECURSION             : set it to "1" to enable recursion or "0" to disable it (e.g. single file)

* entry                 : REPO_DOWNLOAD_PROXMOX_REPOSITORIES="[SOURCE_URI]:::[RECURSION]"

                        REPO_DOWNLOAD_PROXMOX_REPOSITORIES="http://download.proxmox.com/iso/:::1"

or

* first entry           : REPO_DOWNLOAD_PROXMOX_REPOSITORIES="[SOURCE_URI]:::[RECURSION]"
* additional entry      : REPO_DOWNLOAD_PROXMOX_REPOSITORIES+="|[SOURCE_URI]:::[RECURSION]"

                        REPO_DOWNLOAD_PROXMOX_REPOSITORIES="http://download.proxmox.com/iso/:::1"
                        REPO_DOWNLOAD_PROXMOX_REPOSITORIES+="|http://download.proxmox.com/debian/ceph-reef/:::1"
                        
[^5] Value Description vaiable 'REPO_DOWNLOAD_GIT_REPOSITORIES'
* SOURCE_URI            : source URI which will be used for the syncronisation
* TARGET_PATH           : local folder name which the local files are synced to (<REPO_DOWNLOAD_BASEPATH>/git/<TARGET_PATH>)

* entry                 : REPO_DOWNLOAD_GIT_REPOSITORIES="[SOURCE_URI]:::[TARGET_PATH]"

                        REPO_DOWNLOAD_GIT_REPOSITORIES="https://github.com/gpg/gpgol.git:::gpg/gpgol.git"

or

* first entry           : REPO_DOWNLOAD_GIT_REPOSITORIES="[SOURCE_URI]:::[TARGET_PATH]"
* additional entry      : REPO_DOWNLOAD_GIT_REPOSITORIES+="|[SOURCE_URI]:::[TARGET_PATH]"

                        REPO_DOWNLOAD_GIT_REPOSITORIES+="https://github.com/gpg/gpgol.git:::gpg/gpgol.git"
                        REPO_DOWNLOAD_GIT_REPOSITORIES+="|https://github.com/gpg/gpg4win.git:::gpg/gpg4win.git"
                        
[^6] Value Description vaiable 'REPO_DOWNLOAD_OTHER_REPOSITORIES'
* SOURCE_URI            : source URI which will be used for the syncronisation
* TARGET_PATH           : local folder name which the local files are synced to (<REPO_DOWNLOAD_BASEPATH>/git/<TARGET_PATH>)
* RECURSION             : set it to "1" to enable recursion or "0" to disable it (e.g. single file)

* entry                 : REPO_DOWNLOAD_OTHER_REPOSITORIES="[SOURCE_URI]:::[TARGET_PATH]:::[RECURSION]"

                        REPO_DOWNLOAD_OTHER_REPOSITORIES="https://www.memtest86.com/downloads/memtest86-usb.zip:::memtest:::0"

or

* first entry           : REPO_DOWNLOAD_OTHER_REPOSITORIES="[SOURCE_URI]:::[TARGET_PATH]:::[RECURSION]"
* additional entry      : REPO_DOWNLOAD_OTHER_REPOSITORIES+="|[SOURCE_URI]:::[TARGET_PATH]:::[RECURSION]"

                        REPO_DOWNLOAD_OTHER_REPOSITORIES="https://www.memtest86.com/downloads/memtest86-usb.zip:::memtest:::0"
                        REPO_DOWNLOAD_OTHER_REPOSITORIES+="|https://ftp5.gwdg.de/pub/linux/oracle/OL7/:::oracle/iso:::1"
