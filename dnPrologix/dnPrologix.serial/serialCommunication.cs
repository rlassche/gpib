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
        public  Thread readThread {set; get;}

        // Constructor that takes no arguments:
        public GPIB_USB(string portName, int baudRate)
        {
            serialPort = new SerialPort();

            serialPort.PortName = portName.ToLower();
            //serialPort.PortName = portName;
            serialPort.BaudRate = baudRate;
            serialPort.Parity = (Parity)Enum.Parse(typeof(Parity), "0", true);
            serialPort.DataBits = 8;
            serialPort.StopBits = (StopBits)Enum.Parse(typeof(StopBits), "1", true);
            serialPort.Handshake = (Handshake)Enum.Parse(typeof(Handshake), "0", true);

            // Set the read/write timeouts
            serialPort.ReadTimeout = 500;
            serialPort.WriteTimeout = 500;

            try
            {
                serialPort.Open();
                _continue = true;

                try
                {
                     readThread = new Thread(new ThreadStart(Read));
                    _continue = true;
                     readThread.Start();
                    //readThread.Join();
                }
                catch
                {
                    Console.WriteLine($"ERROR: ");
                    return;
                }
            }
            catch
            {
                var msg = $"Cannot open serial port {portName}";
                throw new Exception(msg);
            }
            initPrologix();
        }
        void initPrologix()
        {
            Console.WriteLine( "Reset Controller ");
            serialPort.WriteLine( "++rst");

            Console.WriteLine( "Issue Device Clear ");
            serialPort.WriteLine( "++clr");

            Console.WriteLine( "Set mode to CONTROLLER ");
            serialPort.WriteLine( "++mode 1");

            Console.WriteLine( "Set EOS to 0 (=CR+LF)");
            serialPort.WriteLine( "++eos 0");

            Console.WriteLine( "Enable read-after-write ") ;
            serialPort.WriteLine( "++auto 1");

            serialPort.WriteLine( "++ver");
            var ver = serialPort.ReadLine() ;
            Console.WriteLine( $"Controller: {ver}");

            serialPort.WriteLine( "FB");
        }
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
                catch (System.OperationCanceledException)
                {
                    var msg = "Joh, problem with serialPort";
                    Console.WriteLine(msg);
                    _continue = false;
                    throw new Exception(msg);
                }
            }
        }
    }
}
