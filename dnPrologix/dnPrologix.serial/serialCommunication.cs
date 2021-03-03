using System;
using System.IO.Ports;
using System.Threading;

namespace dnPrologix.serial
{
    public class GPIB_USB
    {
        public string SharedData;
        private bool _continue;

        // _serialPort is used for READ/WRITE bytes to and from the COM-port
        public SerialPort serialPort { get; }
        public Thread readThread { set; get; }

        // Constructor that takes no arguments:
        public GPIB_USB(string portName, int baudRate)
        {
            SerialPort _serialPort;
            // Create a new SerialPort object with default settings.
            _serialPort = new SerialPort();

            // Allow the user to set the appropriate properties.
            _serialPort.PortName = portName;
            _serialPort.BaudRate = baudRate;
            _serialPort.Parity = (Parity)Enum.Parse(typeof(Parity), "0", true);
            _serialPort.DataBits = 8;
            _serialPort.StopBits = (StopBits)Enum.Parse(typeof(StopBits), "1", true);
            _serialPort.Handshake = (Handshake)Enum.Parse(typeof(Handshake), "0", true);



            // Set the read/write timeouts
            _serialPort.ReadTimeout = 500;
            _serialPort.WriteTimeout = 500;

            _serialPort.Open();
            _continue = true ;
            serialPort = _serialPort;
        }
        public void close() {
            // Thread must exit from loop
            _continue = false ;
        }

        void initPrologix()
        {
            Console.WriteLine("Reset Controller ");
            serialPort.WriteLine("++rst");

            Console.WriteLine("Issue Device Clear ");
            serialPort.WriteLine("++clr");

            Console.WriteLine("Set mode to CONTROLLER ");
            serialPort.WriteLine("++mode 1");

            Console.WriteLine("Set EOS to 0 (=CR+LF)");
            serialPort.WriteLine("++eos 0");

            Console.WriteLine("Enable read-after-write ");
            serialPort.WriteLine("++auto 1");

            serialPort.WriteLine("++ver");
            var ver = serialPort.ReadLine();
            Console.WriteLine($"{ver}");

            serialPort.WriteLine("FB");
        }

        public void Read()
        {
            while (_continue)
            {
                try
                {
                    string message = serialPort.ReadLine();
                    Console.WriteLine(message);
                }
                catch (TimeoutException) { }
            }
            Console.WriteLine( $"Closing serialPort {serialPort.PortName}");
            serialPort.Close() ;
        }

    }
}
