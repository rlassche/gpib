using System;
using Microsoft.EntityFrameworkCore;
using MySqlConnector;

namespace dnPrologix.server.Models
{
    //public class GpibContext : DbContext
    public class GpibContext 
    {
        public string _connectionString ;
        public string ConnectionString { get; set; }

        public GpibContext(string connectionString)
        {
            Console.WriteLine($"GpibContext: {connectionString}");
            this.ConnectionString = connectionString;

        }

/*
        public GpibContext(DbContextOptions<GpibContext> options)
                : base(options)
        {
            Console.WriteLine( "GpibContext met DbContextOptions");
            _connectionString  = this.Database.GetDbConnection().ConnectionString;
            // Long running Stored procedure needs more time!
            // this.Database.SetCommandTimeout(999999999);
        }
        */

        private MySqlConnection GetConnection()
        {
            Console.WriteLine("GetConnection: ");
            return new MySqlConnection(ConnectionString);
        }

        public virtual DbSet<GpibDevice> Account { get; set; }
    }
}