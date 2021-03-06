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


namespace dnPrologix.server
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
             // services.AddDbContext<GpibContext>(options => options.UseMySql(Configuration.GetConnectionString("Default") ) );
             //services.AddDbContext<GpibContext>(options => options.UseMySql( "" );
                            
            //MySqlConnection conn = new MySqlConnection(connStr);      
            services.AddControllersWithViews();
            //
            // Add a custom service. This service can be passed to Controllers.
            //
            services.AddSingleton<IGpibService>( ServiceProvider => new GpibService(Configuration.GetConnectionString("Default")) );
            /*
            services.Add( new ServiceDescriptor(
                                typeof(GpibContext),
                                new GpibContext(Configuration.GetConnectionString("Default"))
                          )
                        );
                        */
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env, IGpibService service)
        {
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

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllerRoute(
                    name: "default",
                    pattern: "{controller=Home}/{action=Index}/{id?}");
            });
        }
    }
}
