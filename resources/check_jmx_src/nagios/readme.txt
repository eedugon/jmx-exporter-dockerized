-------- JMX plugin for Nagios ---------

Java JMX Nagios plugin enables you to monitor JMX attributes in Nagios.
As soon as JMX embedded in Java 5, any Java process may expose parameters to be monitored using JMX interface,
look http://java.sun.com/j2se/1.5.0/docs/guide/management/agent.html and http://java.sun.com/jmx for details
In Java version < 5 it is still possible to expose JMX interface using third party libraries

To see what can be monitored by JMX, run <JDK>/bin/jconsole.exe and connect to 
the host/port you setup in your Java process.

Some examples are:
* standard Java JMX implementation exposes memory, threads, OS, garbage collector parameters
* Tomcat exposes multiple parameters - requests, processing time, threads, etc..
* spring framework allows to expose Java beans parameters to JMX
* your application may expose any attributes for JMX by declaration or explicitly.
* can monitor localhost or remote processes

-------- Installation ---------

Pre-requsisites are:
- Java version 5 JRE

1) Files from "plugin" folder must be copied to /usr/lib/nagios/plugins (or another - where your nagios plugins located)
2) Make sure that check_jmx executable : chmod a+x /usr/lib/nagios/plugins/check_jmx


-------- Check Installation ---------

Run /usr/lib/nagios/plugins/check_jmx -help to see available options

Try run some command, for example:
/usr/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:1616/jmxrmi -O java.lang:type=Memory -A HeapMemoryUsage -K used -I HeapMemoryUsage -J used -vvvv -w 10000000 -c 100000000

(replace 1616 with your JMX port)

This must return something like:

JMX OK HeapMemoryUsage=7715400{committed=12337152;init=0;max=66650112;used=7715400}

-------- Configuration ---------

To see available options use
/usr/lib/nagios/plugins/check_jmx -help

