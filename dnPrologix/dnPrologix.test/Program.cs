// TEST PROGRAM FOR EXPERIMENTS
//
using System;
using System.IO.Ports;
using System.Threading;
using dnPrologix.serial;
using System.Runtime.InteropServices;
using System.IO;

public class PortChat
{
    static private string _version = "1.1";
    static string _compile_date = "05-MAR-2021";
    static bool _continue;
    static SerialPort _serialPort;

    static string defaultSerialPort;
    static string _dataRoot;

    public static void Main()
    {
        string message;

        Console.WriteLine($"GPIB Logger test utility.");
        Console.WriteLine("");
        Console.WriteLine($"Version: {_version}");
        Console.WriteLine($"Compile date: {_compile_date}");

        // Get command line arguments.
        string[] args = Environment.GetCommandLineArgs();

        GPIB_USB g = null;
        // Default config file. Override file with ARGV
        string configFile = "gpib.json";

        if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
        {
            defaultSerialPort = "/dev/ttyUSB0";
        }
        else if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
        {
            defaultSerialPort = "COM5";
        }
        else if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
        {
            defaultSerialPort = "/dev/ttyUSB0";
        }
        else
        {
            Console.WriteLine("What OSPlatform???");
        }

        //try
        //{
        if (args.Length > 1)
        {
            // Use the supplied config file
            configFile = args[1];
        }
        Console.WriteLine(System.Environment.CurrentDirectory);
        Console.WriteLine($"Config file: {configFile}");
        using (StreamReader r = new StreamReader(configFile))
        {
            string json = r.ReadToEnd();
            GpibConfig c = Newtonsoft.Json.JsonConvert.DeserializeObject<GpibConfig>(json);
            //Console.WriteLine(ObjectDumper.Dump(c));
            if (c.dataRoot == null)
            {
                _dataRoot = System.Environment.CurrentDirectory + Path.DirectorySeparatorChar + "data";
            }
            else
            {
                _dataRoot = c.dataRoot;
            }

            if (!Directory.Exists(_dataRoot))
            {
                Console.WriteLine($"ERROR: DATA_ROOT directory {_dataRoot} does not exist");
                return;
            }
            Console.WriteLine($"DATA_ROOT: {_dataRoot}");

            if (c.gpibController != null)
            {
                /*
                try
                {
                    DirectoryInfo di = Directory.CreateDirectory(_dataRoot + Path.DirectorySeparatorChar + "gpib_controller");
                }
                catch (System.IO.DriveNotFoundException e)
                {
                    Console.WriteLine($"ERROR: Cannot create DATA_ROOT/gpib_controller directory. (_dataRoot) : {e.Message}");
                    return;
                }
                */

                Console.WriteLine($"gpibController.device: {c.gpibController.device}");
                defaultSerialPort = c.gpibController.device;

                try
                {
                    string[] initController =null ;
                    // Console.WriteLine( ObjectDumper.Dump( c.gpibController.init ) ) ;
                    if( c.gpibController.init == null ) {
                        Console.WriteLine( "ERROR: NO Gpib Controller init commands found.");
                        Console.WriteLine( "     : gpib.json => GpibController.init [] ");
                        return ;
                    }

                    initController = c.gpibController.init.ToArray() ;
                    g = new GPIB_USB(defaultSerialPort, 9600, initController, _dataRoot);
                    _serialPort = g.serialPort;

                    // Create a Thread for the GPIB-Controller, and 
                    // start the Read method.
                    Thread readThread = new Thread(g.Read);

                    readThread.Start();
                }
                catch (System.IO.FileNotFoundException e)
                {
                    Console.WriteLine(e.Message + " Check config file gpib.json");
                    return;
                }


            }
        }
        //}
        //catch (System.IO.FileNotFoundException e)
        //{
        //    Console.WriteLine($"{e.Message}");
        //    return;
        //}








        _continue = true;
       

        Console.Write("Type QUIT to exit.\n> ");

        StringComparer stringComparer = StringComparer.OrdinalIgnoreCase;
        //
        // In this loop, just read from STDIN and send commands to the Tasks running in the background
        //
        while (_continue)
        {
            message = Console.ReadLine();

            if (stringComparer.Equals("quit", message))
            {
                // Exit this while loop
                _continue = false;
            }
            else
            {
                //_serialPort.WriteLine(
                //    String.Format("<{0}>: {1}", name, message));
                _serialPort.WriteLine(message);
            }
        }

        /* readThread.Join(); */
        // Close the serialPort (and the read Thread)
        g.close();
    }

}
