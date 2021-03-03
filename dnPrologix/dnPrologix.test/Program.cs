// TEST PROGRAM FOR EXPERIMENTS
//
using System;
using System.IO.Ports;
using System.Threading;
using dnPrologix.serial;
using System.Runtime.InteropServices;
public class PortChat
{
    static private string _version = "1.0";
    static string _compile_date = "03-MAR-2021";
    static bool _continue;
    static SerialPort _serialPort;

    static string defaultSerialPort;

    public static void Main()
    {

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
        Console.WriteLine($"GPIB test");
        Console.WriteLine($"Version: {_version}");
        Console.WriteLine($"Compile date: {_compile_date}");
        Console.WriteLine("");

        var g = new GPIB_USB( defaultSerialPort, 9600 );
        _serialPort = g.serialPort;

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
        g.close() ;
    }

}
