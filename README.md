# DOR Services App

This Ruby application provides a REST API for DOR Services.


## Developer Notes

DOR Services App is based on the [Grape](http://intridea.github.io/grape/) API framework.

Because the workflows that the app provides access to use Oracle on the backend, the app requires
the Oracle client gem, [ruby-oci8](https://github.com/kubo/ruby-oci8). In order to install
ruby-oci8, you need to go through a couple of hoops to set up an Oracle client. The easiest approach
is to install the Oracle Instant Client.

1. Download the "Instant Client Package - Basic" and the "Instant Client Package - SDK" from the
[Oracle download page](http://www.oracle.com/technetwork/topics/intel-macsoft-096467.html)
(requires a free Oracle account).

2. Unzip the downloaded zip files into a directory on your computer. For example:

        mkdir /opt/oracle_instantclient/
        cd /opt/oracle_instantclient/
        unzip instantclient-basic-macos.x64-11.2.0.4.0.zip
        unzip instantclient-sdk-macos.x64-11.2.0.4.0.zip

3. Make a symlink to libclntsh.dylib:

        cd /opt/oracle_instantclient/instantclient_11_2
        ln -s libclntsh.dylib.11.1 libclntsh.dylib

4. Set the DYLD\_LIBRARY\_PATH environment variable to point to the recently created Instant Client
directory:

   `export DYLD_LIBRARY_PATH=/opt/oracle_instantclient/instantclient_11_2`

You should now be ready to run `bundle install`. Note that DOR Services App requires Ruby 1.9.3.

To run the tests, use `bundle exec rake`.


## TODO

We could alter the gemspec of workflow archiver to be platform dependent: only install ruby-oci8 on Linux platforms
