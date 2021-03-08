using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using MySqlConnector;
using Microsoft.EntityFrameworkCore;


using dnPrologix.server.Models;
using Pomelo.EntityFrameworkCore.MySql.Infrastructure;
using System.Net.WebSockets;

namespace dnPrologix.server
{
    public class Startup
    {
        Dictionary<Guid, WebSocket> wsConnections = new Dictionary<Guid, WebSocket>();
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            Console.WriteLine("ConfigureServices");
            var cstring = Configuration.GetConnectionString("Default");
            // Use DbSet  to push table definitions to the database (if you want)
            // So, migrations
            services.AddDbContextPool<GpibContext>(
                dbContextOptions => dbContextOptions
                    .UseMySql(
                        // Replace with your connection string.
                        cstring,
                        // Replace with your server version and type.
                        // For common usages, see pull request #1233.
                        new MySqlServerVersion(new Version(10, 1, 48)), // use MariaDbServerVersion for MariaDB
                        mySqlOptions => mySqlOptions
                            .CharSetBehavior(CharSetBehavior.NeverAppend))
                    // Everything from this point on is optional but helps with debugging.
                    .EnableSensitiveDataLogging()
                    .EnableDetailedErrors()
            );


            services.AddControllersWithViews();
            //
            // Add a custom service. This service can be passed to Controllers.
            //
            services.AddSingleton<IGpibService>(ServiceProvider => new GpibService(Configuration.GetConnectionString("Default")));
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env, IGpibService service)
        {
            Console.WriteLine("Configure");
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseExceptionHandler("/Home/Error");
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
            }
            // app.UseHttpsRedirection();
            app.UseStaticFiles();

            app.UseRouting();

            app.UseAuthorization();

            Console.WriteLine("add.UseWebSockets() ;");

            app.UseWebSockets();


            // Handle http upgrades to ws
            app.Use(async (context, next) =>
                         {
                             // A websocket endpoint in the application is /ws
                             if (context.Request.Path == "/ws")
                             {
                                 // Check if the request is indead a Websocketrequest
                                 if (context.WebSockets.IsWebSocketRequest)
                                 {
                                     // Do the ws-handshake to accept the connection
                                     using (WebSocket webSocket = await context.WebSockets.AcceptWebSocketAsync())
                                     {
                                         // Generate a Unique Connection Id for administration purposes
                                         var wsConnectionId = Guid.NewGuid();
                                         // Register the connection Id
                                         wsConnections.Add(wsConnectionId, webSocket);

                                         // Console.WriteLine("New WebSocket client. Connection Id: " + wsConnectionId);

                                         // Each connection has it's own Echo space
                                         Console.WriteLine("Create here dhe await Echo....");
                                         await service.Echo(webSocket, wsConnections);
                                         // await Echo(context, webSocket);
                                     }
                                 }
                                 else
                                 {
                                     context.Response.StatusCode = 400;
                                 }
                             }
                             else
                             {
                                 // Pass to the next in the pipeline
                                 await next();
                             }

                         });


            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllerRoute(
                    name: "default",
                    pattern: "{controller=Home}/{action=Index}/{id?}");
            });
        }
    }
}
