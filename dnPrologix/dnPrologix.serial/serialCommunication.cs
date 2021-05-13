using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Ports;
using System.Net.WebSockets;
using System.Text;
using System.Threading;

namespace dnPrologix.serial
{
    public class GPIB_USB
    {
        int _currentAddress=-1;
        public string SharedData;
        private bool _continue;
        private Dictionary<Guid, WebSocket> _wsConnections;

        private string _logFile  ;
        private string _dataRoot ;

        // _serialPort is used for READ/WRITE bytes to and from the COM-port
        public SerialPort serialPort { get; }
        public Thread readThread { set; get; }

        public void setWS(Dictionary<Guid, WebSocket> wsConnections)
        {
            Console.WriteLine("setWS");
            _wsConnections = wsConnections;
        }
        // Display the bytes to the STDOUT of the console 
        public bool consoleOutput { set; get; }

        // Constructor that takes no arguments:
        public GPIB_USB(string portName, int baudRate, string[] initController, string dataRoot,
                        List<GPIBDevice> gpibDevices
            )
        {
            consoleOutput = true ;
            try
            {
                DirectoryInfo di = Directory.CreateDirectory(dataRoot + Path.DirectorySeparatorChar + "gpib_controller");
            }
            catch (System.IO.DriveNotFoundException e)
            {
                Console.WriteLine($"ERROR GPIB_USB: Cannot create DATA_ROOT/gpib_controller directory. (_dataRoot) : {e.Message}");
                return;
            }
            _dataRoot = dataRoot ;
            //_logFile = dataRoot + Path.DirectorySeparatorChar + "gpib_controller" + Path.DirectorySeparatorChar + "deviceData.txt";

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
            _continue = true;
            serialPort = _serialPort;

            for (int i = 0; i < initController.Length; i++)
            {
                Console.WriteLine($"GPIB_USB: init Controller: {initController[i]}");
                serialPort.WriteLine(initController[i]);
            }

            //
            // The gpibDECIVES conntected to this controller
            //
            Console.WriteLine( "Connected gpibDevices to this Controller" );
            //ObjectDumper.Dump( gpibDevices );

            gpibDevices.ForEach( d => {
                Console.WriteLine( $"\tid= {d.id}");
                Console.WriteLine( $"\taddress= {d.address}");
                setGpibAddress( d.address );
                d.init.ForEach( c => {
                    //Console.WriteLine( $"GPIB address {d.address}: cmd={c}");
                    gpibCommand( c ) ;
                });
            });
        }

        /*
         * Send a command the current GPIB device
        */
        public  void gpibCommand( string command  ) {
            Console.WriteLine( $"> gpibComamand: address: {_currentAddress} -- gpibCommand {command}");
            serialPort.WriteLine( command );
        }
        public void setGpibAddress( int address ) {
            _currentAddress = address;
            Console.WriteLine( $"> setGpibAddress to {address}");
            serialPort.WriteLine( $"++addr {address}");
        }
        public void close()
        {
            // Thread must exit from loop
            _continue = false;
        }

        /*
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
        */

        public async void Read()
        {
            // StreamWriter writer = new StreamWriter(_logFile);  
            StreamWriter writer = null ;
            Console.WriteLine( $"GPIB_USB: Read is started.");

            string fileName = _dataRoot + Path.DirectorySeparatorChar + "gpib_controller" + Path.DirectorySeparatorChar + "deviceData_";
            int fileCount = 0 ;
            int readCount=0;
            while (_continue)
            {
                try
                {
                    // Read from serialPort.
                    string message = serialPort.ReadLine();
                    // Write to file
                    if( readCount++ % 100 == 0 ) {
                        if( writer != null ) {
                            writer.Close() ;
                        }
                        fileCount++  ;
                        //string newfileName = fileCount.ToString( "000000.##");
                        writer = new StreamWriter( fileName + fileCount.ToString( "000000.##")+ ".log");
                        Console.WriteLine( "Create file: "+ fileCount.ToString("000000.##"));
                    }
                    //Console.WriteLine( $"DATA to file: {message}");
                    // Write the bytes from the serialPort to the log-file
                    writer.Write( message );

                    if( consoleOutput ) {
                        Console.WriteLine(message);
                    }

                    if (_wsConnections != null)
                    {
                        var x = Encoding.UTF8.GetBytes(message);
                        foreach (var item in _wsConnections)
                        {
                            Console.WriteLine("WS: Send to ONE client");
                            await item.Value.SendAsync(new ArraySegment<byte>(x), WebSocketMessageType.Text, true, CancellationToken.None);
                        }
                    }
                }
                catch (TimeoutException) { }
            }
            Console.WriteLine($"Closing serialPort {serialPort.PortName}");
            serialPort.Close();

            Console.WriteLine( "Closing log file ");
            writer.Close() ;
        }

        public void Read2(object v)
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
            Console.WriteLine($"Closing serialPort {serialPort.PortName}");
            serialPort.Close();
        }
    }
}
