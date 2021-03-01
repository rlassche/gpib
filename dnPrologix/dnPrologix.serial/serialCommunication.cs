using System;
using System.IO.Ports;

namespace dnPrologix.serial
{
    public class GPIB_USB
    {
        private bool _continue;

        // _serialPort is used for READ/WRITE bytes to and from the COM-port
        public SerialPort serialPort { get; }

        // Constructor that takes no arguments:
        public GPIB_USB(string portName, int baudRate)
        {
            serialPort = new SerialPort();

            serialPort.PortName = portName.ToLower();
            serialPort.BaudRate = baudRate;
            serialPort.Parity = (Parity)Enum.Parse(typeof(Parity), "0", true);
            serialPort.DataBits = 8;
            serialPort.StopBits = (StopBits)Enum.Parse(typeof(StopBits), "1", true);
            serialPort.Handshake = (Handshake)Enum.Parse(typeof(Handshake), "0", true);

            // Set the read/write timeouts
            serialPort.ReadTimeout = 500;
            serialPort.WriteTimeout = 500;

            serialPort.Open();
            _continue = true ;
        }

        // Read data from the serial device
        public void Read()
        {
            while (_continue)
            {
                try
                {
                    // Block here for bytes to arrive
                    string message = serialPort.ReadLine();

                    // Send data to STDOUT
                    Console.WriteLine(message);
                }
                catch (TimeoutException) { }
            }
        }
    }
}
