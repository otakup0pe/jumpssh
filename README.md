Jump SSH Helper
===============

Much as I often need to [juggle](http://blog.jonathanfreedman.bio/post/112089594641/juggling-clouds) multiple AWS accounts the same is true for forwarding various TCP streams over SOCKS5 tunnels. The scripts in this repository provide a wrapper around autossh, and some shell aliases to help make life a little easier.

The autossh component keeps the SOCKS5 connections always open and the various shell helpers allow you to easily run such commands as curl, ssh, and scp over them. Normal SOCKS5 applications of course also should work with this setup. Note that DNS queries may also be forwarded over this SOCSK5 connection if your application supports that.

Installation
------------

Clone this repository to somewhere comfortable on your workstation. There are some environment variables which are needed for the scripts. Define these as you wish and then source the `init.sh` script in you `.profile`.

* `JUMPSSH_PATH` points to the path where you have installed this script
* `JUMPSSH_SOCKS` points to the bash config file used to store your SSH jump hosts, associated SOCKS5 ports, and a list of hosts to remain connected to.
* `JUMPSSH_TMP` points to a directory (which will be created if needed) where the various autossh pid files are kept. It will default to `${JUMPSSH_PATH}/tmp`

````
JUMPSSH_PATH="${HOME}/jumpssh
JUMPSSH_SOCKS="${HOME}/.jumpssh"
. "${HOME}/src/jumpssh/init.sh"
````

Configuration
-------------

It helps to have a friendly `.ssh/config` setup already. Generally you will want a short name for the jump hosts and the appropriate `DynamicForward` rules in place. Add other directives as you see fit - the important one for SOCKS5 is `DynamicForward`.

````
Host example
     Hostname jump.example.com
     DynamicForward 3128
````

Configuration otherwise involves a single file containing bash enviornment parameters. The first variable is used to control which ssh connections are kept alive by autossh. The remaining variables are used to look up the SOCKS5 port from the shotname for the jump host.

The following configuration would auto start one SOCKS5 tunnel and route things on it's normal port.

````
JUMPSSH_AUTO="example"
example_PORT=3128
````

Usage
-----

The `jumpauto` script, which wraps autossh, is in the style of an init script. It takes the actions `stop`, `start`, and `status`. It will read `JUMPSSH_AUTO` from the `JUMPSSH_SOCKS` file you defined and control autossh instances accordingly. You will want to ensure that your ssh instances are alive and well before attempting to use the SOCKS5 tunnels. You may also pass it a jump short name as the second argument if you wish to only work with one at a time.

There are three shell helpers for ssh, scp, and curl. Usage is simple. The first argument will be the shorthand name of the SOCKS5 tunnel, and the remaining arguments will be passed in to the called program.

`jumpssh example hidden.example.com`

`jumpscp example /tmp/foo hidden.example.com:/tmp`

`jumpcurl example http://hidden.example.com/'`