using System;
using System.Collections.Generic;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;

namespace dnPrologix.server.Models
{
    public class GpibService : IGpibService
    {
        public GpibService()
        {
            Console.WriteLine("GpibService zonder argument");
        }
        public GpibService(string connectString)
        {
            Console.WriteLine("************************");
            Console.WriteLine($"GpibService met argument: {connectString}");
            Console.WriteLine("************************");



        }
        public string dbConnection()
        {
            return "TEST VAN ROB";
        }

        public bool AddGpibDevice()
        {
            Console.WriteLine("AddGpibDevice");
            return true;
        }
        private WebSocket _webSocket = null;

        public async Task wsSendToAll(string msg)
        {
            Console.WriteLine($"wsSendToAll: {msg}");
            var x = Encoding.UTF8.GetBytes(msg);
            foreach (var item in _wsConnections)
            {
                Console.WriteLine( "Send to ONE client");
                await item.Value.SendAsync(new ArraySegment<byte>(x), WebSocketMessageType.Text, true, CancellationToken.None);
            }

        }
        Dictionary<Guid, WebSocket> _wsConnections = null;
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
        bool AddGpibDevice();
        string dbConnection();
        //async Task Echo(HttpContext contextxxx, WebSocket webSocket, Dictionary<Guid, WebSocket> wsConnections );
        //Task Echo() ;
        Task Echo(WebSocket webSocket, Dictionary<Guid, WebSocket> wsConnections);
        Task wsSendToAll(string msg);
    }
}