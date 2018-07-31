PyD and dub
=================

add pyd to dub.json, e.g.

.. code-block:: json

	"dependencies": {
        "pyd": "~master"
    }

if you are working with Python 2.7, this is sufficient. Otherwise,
you will need to add a subConfiguration, e.g.

.. code-block:: json

   "subConfigurations": {
        "pyd": "python36"
   }

for embedded python and

.. code-block:: json

   "subConfigurations": {
        "pyd": "python36-shared"
   }

for python extensions.

If no packaged subConfiguration will do, you will have to make your own. There 
is a utility script, generate_dub_config.py, to get you started, e.g.

.. code-block:: shell
    pip install pyd six
    python -mpyd.generate_dub_config

