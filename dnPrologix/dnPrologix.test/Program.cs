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

    public static void Main()
    {
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

        try
        {
            if (args.Length > 1)
            {
                // Use the supplied config file
                configFile = args[1];
            }
            Console.WriteLine($"Config file: {configFile}");
            using (StreamReader r = new StreamReader(configFile))
            {
                string json = r.ReadToEnd();
                GpibConfig c = Newtonsoft.Json.JsonConvert.DeserializeObject<GpibConfig>(json);
                //Console.WriteLine(ObjectDumper.Dump(c));
                Console.WriteLine($"gpibController.device: {c.gpibController.device}");
                if (c.gpibController.device != null)
                {
                    defaultSerialPort = c.gpibController.device;
                }
            }
        }
        catch (System.IO.FileNotFoundException e)
        {
            Console.WriteLine($"{e.Message}");
            return;
        }




        Console.WriteLine($"GPIB test. Controller device {defaultSerialPort}");
        Console.WriteLine($"Version: {_version}");
        Console.WriteLine($"Compile date: {_compile_date}");
        Console.WriteLine("");

        try
        {
            g = new GPIB_USB(defaultSerialPort, 9600);
            _serialPort = g.serialPort;
        }
        catch (System.IO.FileNotFoundException e)
        {
            Console.WriteLine(e.Message + " Check config file gpib.json");
            return;
        }

        string message;
        StringComparer stringComparer = StringComparer.OrdinalIgnoreCase;
        Thread readThread = new Thread(g.Read);

        _continue = true;
        readThread.Start();

        Console.Write("Type QUIT to exit.\n> ");

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
