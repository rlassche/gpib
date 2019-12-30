# Install PyVISA
>
    pip install PyVISA

# Python test script
* With python 2
>
    $ python
    Python 2.7.15+ (default, Oct  7 2019, 17:39:04) 
    [GCC 7.4.0] on linux2
    Type "help", "copyright", "credits" or "license" for more information.
    >>> import Gpib
    >>> inst = Gpib.Gpib(0,16) # address 6
    >>> inst.write("*IDN?")
    >>> inst.read(100) # read 100 bytes
    'KEITHLEY INSTRUMENTS INC.,MODEL 2015,104xxxx,B15  /A02  \n'

* With python3
>
    $ python3
    Python 3.6.8 (default, Oct  7 2019, 12:59:55) 
    [GCC 8.3.0] on linux
    Type "help", "copyright", "credits" or "license" for more information.
    >>> import Gpib
    >>> ...

* visa test
>
    $ python
    import visa
    resources = visa.ResourceManager('@py')
    tektronix = resources.open_resource( "GPIB0::14::INSTR" )
    print("Send 'ID?' " )
    tektronix_result = tektronix.query( "ID?" )
    print( tektronix_result )

* pyvisa test
>
    >>> import pyvisa
    >>> rm = pyvisa.ResourceManager()
    >>> rm.list_resources()


## Trouble shooting

[ImportError: cannot import name main when running pip](https://stackoverflow.com/questions/28210269/importerror-cannot-import-name-main-when-running-pip-version-command-in-windo)