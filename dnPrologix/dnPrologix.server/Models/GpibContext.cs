using System;
using Microsoft.EntityFrameworkCore;
// using MySqlConnector;

namespace dnPrologix.server.Models
{
    public class GpibContext : DbContext
    //public class GpibContext 
    {
        public string _connectionString;

        public GpibContext(DbContextOptions<GpibContext> options)
                : base(options)
        {
            Console.WriteLine("GpibContext met DbContextOptions");
            _connectionString = this.Database.GetDbConnection().ConnectionString;
            // Long running Stored procedure needs more time!
            this.Database.SetCommandTimeout(999999999);
        }

        public virtual DbSet<GpibDevice> GpibDevice { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<GpibDevice>(entity =>
            {
                entity.ToTable("GPIB_DEVICE");
                entity.HasKey(e => new { e.DEVICE_ID });
            });
        }
    }
}