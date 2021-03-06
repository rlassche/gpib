using System;

namespace dnPrologix.server.Models
{
    public class GpibService : IGpibService
    {
        public GpibService()
        {
            Console.WriteLine("GpibService zonder argument");
        }
        public GpibService( string connectString)
        {
            Console.WriteLine( "************************");
            Console.WriteLine($"GpibService met argument: {connectString}");
            Console.WriteLine( "************************");
        }
        public string dbConnection() {
            return "TEST VAN ROB";
        }

        public bool AddGpibDevice()
        {
            Console.WriteLine("AddGpibDevice");
            return true;
        }
    }
    public interface IGpibService
    {
        bool AddGpibDevice() ;
        string dbConnection() ;

    }
}