using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using dnPrologix.server.Models;

namespace dnPrologix.server.Controllers
{
    public class HomeController : Controller
    {
        private IGpibService _service ;
        private readonly ILogger<HomeController> _logger;

        /*
        public HomeController( ) {
            Console.WriteLine( "HomeController zonder parameter ");
            _service = new GpibService() ;
        }
        */
        /*
        public HomeController( IGpibService service ) {
            Console.WriteLine( "HomeController met IGpibService");
            _service = service ;

        }
        */
        // public HomeController(ILogger<HomeController> logger, IGpibService service, GpibContext db)
        public HomeController(ILogger<HomeController> logger, IGpibService service )
        {
            Console.WriteLine( "HomeController met ILogger en IGpibService en GpibContext");
            _logger = logger;
            _service = service ;
            Console.WriteLine( "TESTJE: "+ service.dbConnection() );
            
            _service.AddGpibDevice() ;
        }

        public IActionResult Index()
        {
            return View();
        }

        public IActionResult Privacy( )
        {
            Console.WriteLine( "HomeController.Privacy");
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
