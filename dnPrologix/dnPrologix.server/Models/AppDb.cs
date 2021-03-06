using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MySqlConnector;
//using Microsoft.Data.SqlClient;

namespace dnPrologix.server.Models {
    // Application Database Object 
    public class AppDb : IDisposable
    {
        public MySqlConnection Connection { get; }

        public AppDb(string connectionString)
        {
            Connection = new MySqlConnection(connectionString);
        }

        public void Dispose() => Connection.Dispose();
    }
}

