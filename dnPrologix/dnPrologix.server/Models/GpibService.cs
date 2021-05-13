using System;
using System.Collections.Generic;
using System.IO.Ports;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using dnPrologix.serial;
using Microsoft.AspNetCore.Http;

namespace dnPrologix.server.Models
{
    public class GpibService : IGpibService
    {
        // List with ALL connected webSocket clients
        Dictionary<Guid, WebSocket> _wsConnections = null;
        private SerialPort _serialPort;

        private string _gpibConfigFilename = null ;

        private GPIB_USB _g = null;
        private WebSocket _webSocket = null;

        public GpibService()
        {
            Console.WriteLine("GpibService zonder argument");
        }
        public GpibService(string connectString, string gpibConfigFile)
        {
            Console.WriteLine("************************");
            Console.WriteLine($"GpibService Controller met argument: {connectString}");
            Console.WriteLine($"                                   : {gpibConfigFile}");
            Console.WriteLine("************************");
            _gpibConfigFilename = gpibConfigFile ;
        }
        /*
        public string dbConnection()
        {
            return "TEST VAN ROB";
        }
        */


        public void sendToGpibController( string message ) {
            Console.WriteLine( "sendToGpibController");
             _serialPort.WriteLine(message);
        }
        public async Task<bool>  AddGpibDevice(Dictionary<Guid, WebSocket> wsClients)
        {
            Console.WriteLine( $"OKAY, CONFIG FILE FOR GPIB: {_gpibConfigFilename}" ) ;
            Console.WriteLine( "TODO : DESERIALIZE THE JSON FILE");
            string defaultSerialPort = "COM5";
            Console.WriteLine( $"AddGpibDevice: {defaultSerialPort}");
            try
            {
                string[] cmds = new string[] { "++clr"} ;
                _g = new GPIB_USB(defaultSerialPort, 9600 , cmds, "dataroot", null );
                _serialPort = _g.serialPort;
            }
            catch (System.IO.FileNotFoundException e)
            {
                Console.WriteLine(e.Message + " Check config file gpib.json????");
            } 
            catch( System.UnauthorizedAccessException e2) {
                Console.WriteLine( "port is already open: "+ e2.Message );
                //return true;
            }


            _g.setWS( wsClients) ;
            string message;
            StringComparer stringComparer = StringComparer.OrdinalIgnoreCase;
            //Thread readThread = new Thread( ()=>_g.Read2("xx"));
            Thread readThread = new Thread( _g.Read);
            bool _continue = true ;

            readThread.Start();
            return true ;

            Console.Write("Type QUIT to exit.\n> ");

            while (_continue)
            {
                // Read from STDIN
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
            _g.close();
            return true;
        }

        public Task wsSendToAllNone()
        {
            Console.WriteLine( "wsSendToAllNone");
            return Task.CompletedTask;
        }

        // Send a message to ALL connected WebSocket clients
        public async Task wsSendToAll(string msg)
        {
            Console.WriteLine($"wsSendToAll: {msg}");
            var x = Encoding.UTF8.GetBytes(msg);
            foreach (var item in _wsConnections)
            {
                Console.WriteLine("Send to ONE client");
                await item.Value.SendAsync(new ArraySegment<byte>(x), WebSocketMessageType.Text, true, CancellationToken.None);
            }

        }

        // Each connected WebSocket clients has its OWN Echo task
        public async Task Echo(WebSocket webSocket, Dictionary<Guid, WebSocket> wsConnections)
        {
            Console.WriteLine("GpibService: Echo ");
            var buffer = new byte[1024 * 4];
            Console.WriteLine("Start of Echo for a new websocket connection, SET _webSocket to a value");
            _wsConnections = wsConnections;

            // Wait for a socket message to arrive 
            WebSocketReceiveResult result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
            while (!result.CloseStatus.HasValue)
            {
                foreach (var item in wsConnections)
                {
                    if (item.Value == webSocket)
                    {
                        // Console.WriteLine("This is the originating connection Id: " + item.Key);
                        await webSocket.SendAsync(new ArraySegment<byte>(buffer, 0, result.Count), result.MessageType, result.EndOfMessage,
                                                  CancellationToken.None);
                    }
                    else
                    {
                        // Console.WriteLine("Sending to subscriber: " + item.Key);
                        await item.Value.SendAsync(new ArraySegment<byte>(buffer, 0, result.Count), result.MessageType, result.EndOfMessage,
                                                  CancellationToken.None);
                    }

                }

                try
                {

                    // Wait for a new message to arrive
                    result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
                }
                catch (System.OperationCanceledException e)
                {
                    Console.WriteLine("Process is terminated.", e.Message);
                }
            }

            /* Remove the closing websocket from the list */
            foreach (var item in wsConnections)
            {
                if (webSocket == item.Value)
                {
                    Console.WriteLine($"Closing connection Id : {item.Key}");
                    wsConnections.Remove(item.Key);
                }
            }
            // Close the connection
            await webSocket.CloseAsync(result.CloseStatus.Value, result.CloseStatusDescription, CancellationToken.None);
        }
    }



    public interface IGpibService
    {
        Task<bool> AddGpibDevice(Dictionary<Guid, WebSocket> wsClients);
        // string dbConnection();
        //async Task Echo(HttpContext contextxxx, WebSocket webSocket, Dictionary<Guid, WebSocket> wsConnections );
        //Task Echo() ;
        Task Echo(WebSocket webSocket, Dictionary<Guid, WebSocket> wsConnections);
        Task wsSendToAll(string msg);

        void sendToGpibController( string message );
        
    }
}