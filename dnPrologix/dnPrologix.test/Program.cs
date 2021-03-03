﻿// TEST PROGRAM FOR EXPERIMENTS
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

        GPIB_USB g = null;
        try
        {
            g = new GPIB_USB(defaultSerialPort, 9600);
            _serialPort = g.serialPort;
        }
        catch (System.Exception e)
        {
            Console.WriteLine($"ERROR 2: {e.Message}");
            // throw new Exception( e.Message );
            return;
        }
        //string name;
        string message;
        StringComparer stringComparer = StringComparer.OrdinalIgnoreCase;
        //Thread readThread = new Thread(Read);
        // Read from the COM-port
        // Thread readThread = new Thread(g.Read);
        /*
        Thread readThread = null;
        try
        {
            readThread = new Thread(new ThreadStart(g.Read));
            _continue = true;
            readThread.Start();
        }
        catch
        {
            Console.WriteLine($"ERROR: ");
            return;
        }
        */


        // Console.WriteLine("Type QUIT to exit");


        Console.Write("> ");
        _continue = true;
        while (_continue)
        {
            //Console.WriteLine($"ROB: waiting for readline input");
            message = Console.ReadLine();
            //Console.WriteLine($"ROB: read message {message}");

            if (stringComparer.Equals("quit", message))
            {
                _continue = false;
            }
            else
            {
                // Console.WriteLine($"ROB: Sending {message}");
                //try
                //{

                _serialPort.WriteLine(message);
                //}
                //catch
                //{
                //   Console.WriteLine($"He, error in sending to {defaultSerialPort}");
                //  _continue = false;
                //}
            }
        }
        Console.WriteLine($"EOF. Good bye");
        try
        {
            g.readThread.Join();
            // readThread.Join();
        }
        catch
        {
            Console.WriteLine("Catch van Join");
        }
        _serialPort.Close();
    }
}
