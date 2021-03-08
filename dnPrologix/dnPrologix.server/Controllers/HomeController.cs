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
        private IGpibService _service;
        private readonly ILogger<HomeController> _logger;

        private GpibContext _db;

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
        public HomeController(ILogger<HomeController> logger, IGpibService service, GpibContext db)
        {
            Console.WriteLine("HomeController met ILogger en IGpibService en GpibContext");
            _db = db;
            _logger = logger;
            _service = service;
            // Console.WriteLine("TESTJE: " + service.dbConnection());
            _service.wsSendToAll( "Dit is HomeController");

            _service.AddGpibDevice();
        }

        public IActionResult Index()
        {
            _service.wsSendToAll( "Dit is HomeController.Index");
            return View();
        }

        public IActionResult Privacy()
        {
            Console.WriteLine("HomeController.Privacy");
            _service.wsSendToAll( "Dit is HomeController.Privacy");
            IEnumerable<GpibDevice> objList = _db.GpibDevice.ToList();
            //Console.WriteLine( ObjectDumper.Dump( objList));

            return View(objList);
        }


        [HttpGet]
        public IActionResult Create()
        {
            Console.WriteLine("HomeController.Create");
            //IEnumerable<GpibDevice> objList = _db.GpibDevice.ToList() ;
            //Console.WriteLine( ObjectDumper.Dump( objList));
            _service.wsSendToAll( "Dit is HomeController.Create");

            return View();
        }

        [HttpGet]
        public IActionResult Edit( int? id )
        {
            _service.wsSendToAll( "Dit is HomeController.Edit");
            if( id == null || id == 0 ) {
                return NotFound() ;
            }
            var obj = _db.GpibDevice.Find( id );
            if( obj == null ) {
                return NotFound() ;
            }
            return View( obj );

            Console.WriteLine("HomeController.Create");
            //IEnumerable<GpibDevice> objList = _db.GpibDevice.ToList() ;
            //Console.WriteLine( ObjectDumper.Dump( objList));

            return View();
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Create(GpibDevice obj)
        {
            Console.WriteLine("HomeController.POST.Create");
            _service.wsSendToAll( "Dit is HomeController.Post.Create");
            if (ModelState.IsValid)
            {

                //IEnumerable<GpibDevice> objList = _db.GpibDevice.ToList() ;
                //Console.WriteLine( ObjectDumper.Dump( objList));
                obj.CONNECTION_TYPE = "prologix-gpib-usb";
                _db.GpibDevice.Add(obj);
                _db.SaveChanges();
                return RedirectToAction("Privacy");
            }
            return View(obj);

        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            _service.wsSendToAll( "Dit is HomeController.Error");
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
