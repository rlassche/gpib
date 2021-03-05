using System;
using System.Collections.Generic;

namespace dnPrologix.serial
{
    public class GpibController    {
        public string device { get; set; } 
        public List<string> init { get; set; } 
    }

    public class GPIBDevice    {
        public string id { get; set; } 
        public int address { get; set; } 
        public List<string> init { get; set; } 
    }

    public class GpibConfig
    {
        public GpibController gpibController { get; set; } 
        public List<GPIBDevice> gpibDevices { get; set; } 
    }
}