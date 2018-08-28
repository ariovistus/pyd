Using Dub to build
==================

To use with dub, either specify the relevant subConfiguration for your python version,
or run :code:`source pyd_set_env_vars.sh <your python>` on linux or
:code:`pyd_set_env_vars.bat <your python>` on windows to set the relevant environment variables
and use the :code:`env` subConfiguration.

These scripts can be run from any directory, but to facilitate using PyD as a dependency
pulled from the dub registry you can run :code:`dub run pyd:setup` to copy them to the current
directory for use, e.g. given you are in the current directory of a package that depends
on pyd, run :code:`dub run pyd:setup` followed by :code:`source pyd_set_env_vars.sh`, then build
your package as normal.


