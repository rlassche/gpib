using System;
using System.IO.Ports;
using System.Threading;
using dnPrologix.serial;

namespace dnPrologix.console
{
    class Program
    {
        static SerialPort _serialPort;
        static void Main(string[] args)
        {
            var g = new GPIB_USB("COM5", 9600);
            _serialPort = g.serialPort;
        }
    }
}
