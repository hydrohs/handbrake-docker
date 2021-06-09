# Docker container for HandBrake
This is a Docker container for [HandBrake](https://handbrake.fr/). Based on this [container](https://github.com/jlesage/docker-handbrake).

The GUI of the application is accessed through a modern web browser (no installation or configuration needed on the client side) or via ssh using [Xpra](https://xpra.org).

A fully automated mode is also available: drop files into a watch folder and let HandBrake process them without any user interaction.

---

[![HandBrake logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/handbrake-icon.png&w=200)](https://handbrake.fr/)[![HandBrake](https://dummyimage.com/400x110/ffffff/575757&text=HandBrake)](https://handbrake.fr/)

HandBrake is a tool for converting video from nearly any format to a selection of modern, widely supported codecs.

---

## Table of Contents

   * [Docker container for HandBrake](#docker-container-for-handbrake)
      * [Table of Contents](#table-of-contents)
      * [Quick Start](#quick-start)
      * [Usage](#usage)
         * [Environment Variables](#environment-variables)
         * [Data Volumes](#data-volumes)
         * [Ports](#ports)
         * [Changing Parameters of a Running Container](#changing-parameters-of-a-running-container)
      * [Docker Compose File](#docker-compose-file)
      * [Docker Image Update](#docker-image-update)
         * [Synology](#synology)
         * [unRAID](#unraid)
      * [User/Group IDs](#usergroup-ids)
      * [Accessing the GUI](#accessing-the-gui)
      * [Reverse Proxy](#reverse-proxy)
         * [Apache](#apache)
         * [Nginx](#nginx)
      * [Shell Access](#shell-access)
      * [Automatic Video Conversion](#automatic-video-conversion)
         * [Multiple Watch Folders](#multiple-watch-folders)
         * [Video Discs](#video-discs)
         * [Hooks](#hooks)
         * [Temporary Conversion Directory](#temporary-conversion-directory)

## Quick Start

**NOTE**: The Docker command provided in this quick start is given as an example
and parameters should be adjusted to your need.

Launch the HandBrake docker container with the following command:
```
docker run -d \
    --name=handbrake \
    -p 2200:2200 \
    -p 10000:10000 \
    -v $HOME/.ssh/authorized_keys:/authorized_keys:ro \
    -v /docker/appdata/handbrake:/config:rw \
    -v $HOME:/storage:ro \
    -v $HOME/HandBrake/watch:/watch:rw \
    -v $HOME/HandBrake/output:/output:rw \
    .
```

Where:
  - `$HOME/.ssh/authorized_keys:/authorized_keys:ro`: Is the file which contains SSH public keys for connecting via SSH.
  - `/docker/appdata/handbrake`: This is where the application stores its configuration, log and any files needing persistency.
  - `$HOME`: This location contains files from your host that need to be accessible by the application.
  - `$HOME/HandBrake/watch`: This is where videos to be automatically converted are located.
  - `$HOME/HandBrake/output`: This is where automatically converted video files are written.

Browse to `http://your-host-ip:10000` to access the HandBrake GUI, or from a client with Xpra installed `xpra attach ssh://your-host-ip:2200/10`.
Files from the host appear under the `/storage` folder in the container.

## Usage

```
docker run [-d] \
    --name=handbrake \
    [-e <VARIABLE_NAME>=<VALUE>]... \
    [-v <HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]]... \
    [-p <HOST_PORT>:<CONTAINER_PORT>]... \
    .
```
| Parameter | Description |
|-----------|-------------|
| -d        | Run the container in the background.  If not set, the container runs in the foreground. |
| -e        | Pass an environment variable to the container.  See the [Environment Variables](#environment-variables) section for more details. |
| -v        | Set a volume mapping (allows to share a folder/file between the host and the container).  See the [Data Volumes](#data-volumes) section for more details. |
| -p        | Set a network port mapping (exposes an internal container port to the host).  See the [Ports](#ports) section for more details. |

### Environment Variables

To customize some properties of the container, the following environment
variables can be passed via the `-e` parameter (one for each variable).  Value
of this parameter has the format `<VARIABLE_NAME>=<VALUE>`.

| Variable       | Description                                  | Default |
|----------------|----------------------------------------------|---------|
|`UID`| ID of the user the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`GID`| ID of the group the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`UMASK`| Mask that controls how file permissions are set for newly created files. The value of the mask is in octal notation.  By default, this variable is not set and the default umask of `022` is used, meaning that newly created files are readable by everyone, but only writable by the owner. See the following online umask calculator: http://wintelguy.com/umask-calc.pl | (unset) |
|`TZ`| [TimeZone] of the container.  Timezone can also be set by mapping `/etc/localtime` between the host and the container. | `Etc/UTC` |
|`AUTOMATED_CONVERSION_PRESET`| HandBrake preset used by the automatic video converter.  Identification of a preset must follow the format `<CATEGORY>/<PRESET NAME>`.  See the [Automatic Video Conversion](#automatic-video-conversion) section for more details. | `General/Very Fast 1080p30` |
|`AUTOMATED_CONVERSION_FORMAT`| Video container format used by the automatic video converter for output files.  This is typically the video filename extension.  See the [Automatic Video Conversion](#automatic-video-conversion) section for more details. | `mp4` |
|`AUTOMATED_CONVERSION_KEEP_SOURCE`| When set to `0`, a video that has been successfully converted is removed from the watch folder. | `1` |
|`AUTOMATED_CONVERSION_VIDEO_FILE_EXTENSIONS`| Space-separated list of file extensions to be considered as video files.  By default, this list is empty, meaning that the automatic video converter will let HandBrake automatically detects if a file, no matter its extension, is a video or not (note that extensions defined by the `AUTOMATED_CONVERSION_NON_VIDEO_FILE_EXTENSIONS` environment variable are always considered as non-video files).  Normally, this variable doesn't need to be set.  Usage of this variable is useful when only specific video files need to converted. | (unset) |
|`AUTOMATED_CONVERSION_NON_VIDEO_FILE_ACTION`| When set to `ignore`, a non-video file found in the watch folder is ignored.  If set to `copy`, a non-video file is copied as-is to the output folder. | `ignore` |
|`AUTOMATED_CONVERSION_NON_VIDEO_FILE_EXTENSIONS`| Space-separated list of file extensions to be considered as not being videos.  Most non-video files are properly rejected by HandBrake.  However, some files, like images, are convertible by HandBrake even if they are not video files. | `jpg jpeg bmp png gif txt nfo` |
|`AUTOMATED_CONVERSION_OUTPUT_DIR`| Root directory where converted videos should be written. | `/output` |
|`AUTOMATED_CONVERSION_OUTPUT_SUBDIR`| Subdirectory of the output folder into which converted videos should be written.  By default, this variable is not set, meaning that videos are saved directly into `/output/`.  If `Home/Movies` is set, converted videos will be written to `/output/Home/Movies`.  Use the special value `SAME_AS_SRC` to use the same subfolder as the source.  For example, if the video source file is `/watch/Movies/mymovie.mkv`, the converted video will be written to `/output/Movies/`. | (unset) |
|`AUTOMATED_CONVERSION_OVERWRITE_OUTPUT`| Setting this to `1` allows the final destination file to be overwritten if it already exists. | `0` |
|`AUTOMATED_CONVERSION_SOURCE_STABLE_TIME`| Time (in seconds) during which properties (e.g. size, time, etc) of a video file in the watch folder need to remain the same.  This is to avoid processing a file that is being copied. | `5` |
|`AUTOMATED_CONVERSION_SOURCE_MIN_DURATION`| Minimum title duration (in seconds).  Shorter titles will be ignored.  This applies only to video disc sources (ISO file, `VIDEO_TS` folder or `BDMV` folder). | `10` |
|`AUTOMATED_CONVERSION_CHECK_INTERVAL`| Interval (in seconds) at which the automatic video converter checks for new files. | `5` |
|`AUTOMATED_CONVERSION_MAX_WATCH_FOLDERS`| Maximum number of watch folders handled by the automatic video converter. | `5` |
|`HANDBRAKE_DEBUG`| Setting this to `1` enables HandBrake debug logging for both the GUI and the automatic video converter.  For the latter, the increased verbosity is reflected in `/config/log/hb/conversion.log` (container path).  For the GUI, log messages are sent to `/config/log/hb/handbrake.debug.log` (container path).  **NOTE**: When enabled, a lot of information is generated and the log file will grow quickly.  Make sure to enable this temporarily and only when needed. | (unset) |
|`AUTOMATED_CONVERSION_NO_GUI_PROGRESS`| When set to `1`, progress of videos converted by the automatic video converter is not shown in the HandBrake GUI. | `0` |
|`AUTOMATED_CONVERSION_HANDBRAKE_CUSTOM_ARGS`| Custom arguments to pass to HandBrake when performing a conversion. | (unset) |
|`AUTOMATED_CONVERSION_INSTALL_PKGS`| Space-separated list of Alpine Linux packages to install.  This is useful when the automatic video converter's hooks require tools not available in the container image.  See https://pkgs.alpinelinux.org/packages?name=&branch=v3.9&arch=x86_64 for the list of available Alpine Linux packages. | (unset) |

### Data Volumes

The following table describes data volumes used by the container.  The mappings
are set via the `-v` parameter.  Each mapping is specified with the following
format: `<HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]`.

| Container path  | Permissions | Description |
|-----------------|-------------|-------------|
|`/config`| rw | This is where the application stores its configuration, log and any files needing persistency. |
|`/storage`| ro | This location contains files from your host that need to be accessible by the application. |
|`/watch`| rw | This is where videos to be automatically converted are located. |
|`/output`| rw | This is where automatically converted video files are written. |

### Ports

Here is the list of ports used by the container.  They can be mapped to the host
via the `-p` parameter (one per port mapping).  Each mapping is defined in the
following format: `<HOST_PORT>:<CONTAINER_PORT>`.  The port number inside the
container cannot be changed, but you are free to use any port on the host side.

| Port | Mapping to host | Description |
|------|-----------------|-------------|
| 10000 | Mandatory | Port used to access the application's GUI via the web interface. |
| 2200 | Optional | Port used to access the application's GUI via Xpra, requires Xpra be installed on the client. |

### Changing Parameters of a Running Container

As can be seen, environment variables, volume and port mappings are all specified
while creating the container.

The following steps describe the method used to add, remove or update
parameter(s) of an existing container.  The general idea is to destroy and
re-create the container:

  1. Stop the container (if it is running):
```
docker stop handbrake
```
  2. Remove the container:
```
docker rm handbrake
```
  3. Create/start the container using the `docker run` command, by adjusting
     parameters as needed.

**NOTE**: Since all application's data is saved under the `/config` container
folder, destroying and re-creating a container is not a problem: nothing is lost
and the application comes back with the same state (as long as the mapping of
the `/config` folder remains the same).

## Docker Compose File

Here is an example of a `docker-compose.yml` file that can be used with
[Docker Compose](https://docs.docker.com/compose/overview/).

Make sure to adjust according to your needs.  Note that only mandatory network
ports are part of the example.

```yaml
version: '3'
services:
  handbrake:
    build: .
    ports:
      - "2200:2200"
      - "10000:10000"
    volumes:
      - "$HOME/.ssh/authorized_keys:/authorized_keys:ro"
      - "/docker/appdata/handbrake:/config:rw"
      - "$HOME:/storage:ro"
      - "$HOME/HandBrake/watch:/watch:rw"
      - "$HOME/HandBrake/output:/output:rw"
```

## Docker Image Update

If the system on which the container runs doesn't provide a way to easily update
the Docker image, the following steps can be followed:

  1. Fetch the latest image:
```
docker pull hydrohs/handbrake
```
  2. Stop the container:
```
docker stop handbrake
```
  3. Remove the container:
```
docker rm handbrake
```
  4. Start the container using the `docker run` command.

### Synology

For owners of a Synology NAS, the following steps can be used to update a
container image.

  1.  Open the *Docker* application.
  2.  Click on *Registry* in the left pane.
  3.  In the search bar, type the name of the container (`jlesage/handbrake`).
  4.  Select the image, click *Download* and then choose the `latest` tag.
  5.  Wait for the download to complete.  A  notification will appear once done.
  6.  Click on *Container* in the left pane.
  7.  Select your HandBrake container.
  8.  Stop it by clicking *Action*->*Stop*.
  9.  Clear the container by clicking *Action*->*Clear*.  This removes the
      container while keeping its configuration.
  10. Start the container again by clicking *Action*->*Start*. **NOTE**:  The
      container may temporarily disappear from the list while it is re-created.

### unRAID

For unRAID, a container image can be updated by following these steps:

  1. Select the *Docker* tab.
  2. Click the *Check for Updates* button at the bottom of the page.
  3. Click the *update ready* link of the container to be updated.

## User/Group IDs

When using data volumes (`-v` flags), permissions issues can occur between the
host and the container.  For example, the user within the container may not
exists on the host.  This could prevent the host from properly accessing files
and folders on the shared volume.

To avoid any problem, you can specify the user the application should run as.

This is done by passing the user ID and group ID to the container via the
`UID` and `GID` environment variables.

To find the right IDs to use, issue the following command on the host, with the
user owning the data volume on the host:

    id <username>

Which gives an output like this one:
```
uid=1000(myuser) gid=1000(myuser) groups=1000(myuser),4(adm),24(cdrom),27(sudo),46(plugdev),113(lpadmin)
```

The value of `uid` (user ID) and `gid` (group ID) are the ones that you should
be given the container.

## Accessing the GUI

Assuming that container's ports are mapped to the same host's ports, the
graphical interface of the application can be accessed via:

  * A web browser:
```
http://<HOST IP ADDR>:10000
```

  * Via Xpra:
```
xpra attach ssh://<HOST IP ADDR>:2200/10
```

## Reverse Proxy

Xpra provides example configurations for both Apache and Nginx

### Apache

```
<Location "/xpra">

  RewriteEngine on
  RewriteCond %{HTTP:UPGRADE} ^WebSocket$ [NC]
  RewriteCond %{HTTP:CONNECTION} ^Upgrade$ [NC]
  RewriteRule .* ws://localhost:14500/%{REQUEST_URI} [P]

  ProxyPass ws://localhost:14500
  ProxyPassReverse ws://localhost:14500

  ProxyPass http://localhost:14500
  ProxyPassReverse http://localhost:14500
</Location>
```

### Nginx

```
server {
  listen        443 ssl http2;
  listen        [::]:443 ssl http2;
  server_name   www.example.com;

  location ^~ /xpra/ {
    proxy_pass       http://127.0.0.1:10000/;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
  }
```
## Shell Access

To get shell access to the running container, execute the following command:

```
docker exec -ti CONTAINER sh
```

Where `CONTAINER` is the ID or the name of the container used during its
creation (e.g. `crashplan-pro`).

## Automatic Video Conversion

This container has an automatic video converter built-in.  This is useful to
batch-convert videos without user interaction.

Basically, files copied to the `/watch` container folder are automatically
converted by HandBrake to a pre-defined video format according to a pre-defined
preset.  Both the format and the preset are specified via environment variables:

| Variable       | Default |
|----------------|---------|
|`AUTOMATED_CONVERSION_PRESET` | "General/Very Fast 1080p30" |
|`AUTOMATED_CONVERSION_FORMAT` | "mp4" |

See the [Environment Variables](#environment-variables) section for details
about setting environment variables.

**NOTE**: A preset is identified by its category and its name.

**NOTE**: All default presets, along with personalized/custom ones, can be seen
with the HandBrake GUI.

**NOTE**: Converted videos are stored, by default, to the `/output` folder of
the container.

**NOTE**: The status and progression of conversions performed by the automatic
video converter can be seen from both the GUI and the container's log.
Container's log can be obtained by executing the command
`docker logs handbrake`, where `handbrake` is the name of the container.  Also,
full details about the conversion are stored in `/config/log/hb/conversion.log`
(container path).

### Multiple Watch Folders

If needed, up to 4 additionnal watch folders can be used:
  - `/watch2`
  - `/watch3`
  - `/watch4`
  - `/watch5`

This is useful in scenarios where videos need to be converted by different
presets.  For example, one could use a watch folder for movies and another watch
folder for TV shows, both having different encoding quality requirements.

By default, additional watch folders inherits the same settings has the main one
(`/watch`).  A setting for a particular watch folder can be overrided by adding
its index to the corresponding environment variable name.

For example, to set the HandBrake preset used to convert videos in `/watch2`,
the environment variable `AUTOMATED_CONVERSION_PRESET_2` is used.
`AUTOMATED_CONVERSION_PRESET_3` is used for `/watch3`, and so on.

All settings related to the automatic video converter can be overrided for each
additional watch folder:
  - `AUTOMATED_CONVERSION_PRESET`
  - `AUTOMATED_CONVERSION_FORMAT`
  - `AUTOMATED_CONVERSION_SOURCE_STABLE_TIME`
  - `AUTOMATED_CONVERSION_SOURCE_MIN_DURATION`
  - `AUTOMATED_CONVERSION_OUTPUT_DIR`
  - `AUTOMATED_CONVERSION_OUTPUT_SUBDIR`
  - `AUTOMATED_CONVERSION_OVERWRITE_OUTPUT`
  - `AUTOMATED_CONVERSION_KEEP_SOURCE`
  - `AUTOMATED_CONVERSION_VIDEO_FILE_EXTENSIONS`
  - `AUTOMATED_CONVERSION_NON_VIDEO_FILE_ACTION`
  - `AUTOMATED_CONVERSION_NON_VIDEO_FILE_EXTENSIONS`

### Video Discs

The automatic video converter supports video discs, in the folllowing format:
  - ISO image file.
  - `VIDEO_TS` folder (DVD disc).
  - `BDMV` folder (Blu-ray disc).

Note that folder names are case sensitive.  For example, `video_ts`, `Video_Ts`
or `Bdmv` won't be treated as discs, but as normal directories.

Video discs can have multiple titles (the main movie, previews, extras, etc).
In a such case, each title is converted to its own file.  These files have the
suffix `.title-XX`, where `XX` is the title number. For example, if the file
`MyMovie.iso` has 2 titles, the following files would be generated:
  - `MyMovie.title-1.mp4`
  - `MyMovie.title-2.mp4`

It is possible to ignore titles shorted than a specific amount of time.  By
default, only titles longer than 10 seconds are processed.  This duration can be
adjusted via the `AUTOMATED_CONVERSION_SOURCE_MIN_DURATION` environment
variable.  See the [Environment Variables](#environment-variables) section for
details about setting environment variables.

When the source is a disc folder, the name of the converted video file will
match its parent folder's name, if any.  For example:

| Watch folder path       | Converted video filename |
|-------------------------|--------------------------|
| /watch/VIDEO_TS         | VIDEO_TS.mp4             |
| /watch/MyMovie/VIDEO_TS | MyMovie.mp4              |

### Hooks

Custom actions can be performed using hooks.  Hooks are shell scripts executed
by the automatic video converter.

**NOTE**: Hooks are always invoked via `/bin/sh`, ignoring any shebang the
script may have.

Hooks are optional and by default, no one is defined.  A hook is defined and
executed when the script is found at a specific location.

The following table describe available hooks:

| Container location | Description | Parameter(s) |
|--------------------|-------------|--------------|
| `/config/hooks/pre_conversion.sh` | Hook executed before the beginning of a video conversion. | The first argument is the path of the converted video.  The second argument is the path to the source file.  Finally, the third argument is the name of the Handbrake preset that will be used to convert the video. |
| `/config/hooks/post_conversion.sh` | Hook executed when the conversion of a video file is terminated. | The first parameter is the status of the conversion.  A value of `0` indicates that the conversion terminated successfuly.  Any other value represent a failure.  The second argument is the path to the converted video (the output).  The third argument is the path to the source file.  Finally, the fourth argument is the name of the Handbrake preset used to convert the video. |
| `/config/post_watch_folder_processing.sh | Hook executed after all videos in the watch folder have been processed. | The path of the watch folder. |

During the first start of the container, example hooks are installed in
`/config/hooks/`.  Example scripts have the suffix `.example`.  For example,
you can use `/config/hooks/post_conversion.sh.example` as a starting point.

**NOTE**: Keep in mind that this container has the minimal set of packages
required to run HandBrake.  This may limit actions that can be performed in
hooks.

### Temporary Conversion Directory

A video being converted is written in a hidden, temporary directory under the
root of the output directory (`/output` by default).  Once a conversion
successfully terminates, the video file is moved to its final location.

This feature can be useful for scenarios where the output folder is monitored
by another application: with proper configuration, one can make sure this
application only "sees" the final, converted video file and not the transient
versions.

If the monitoring application ignores hidden directories, then nothing special
is required and the application should always see the final file.

However, if the monitoring application handles hidden directories, the automatic
video converter should be configured with the
`AUTOMATED_CONVERSION_OUTPUT_SUBDIR` environment variable sets to a
subdirectory.  The application can then be configured to monitor this
subdirectory.  For example, if `AUTOMATED_CONVERSION_OUTPUT_SUBDIR` is set to
`TV Shows` and `/output` is mapped to `$HOME/appvolumes/HandBrake` on the host,
`$HOME/appvolumes/HandBrake/TV Shows` should be monitored by the application.
