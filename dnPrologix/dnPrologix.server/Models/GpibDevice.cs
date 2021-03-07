
using System;
using System.ComponentModel.DataAnnotations;

namespace dnPrologix.server.Models {
    public partial class GpibDevice
    {

        [DisplayAttribute( Name="Device Id")]
        public string DEVICE_ID {get; set;}
        public string CONNECTION_TYPE {get; set;}
        [DisplayAttribute( Name="Description")]
        public string DESCRIPTION {get; set;}
        public int MINOR {get; set;}
        [DisplayAttribute( Name="Primary Address")]
        public int PAD {get; set;}
        public int SAD {get; set;}
        public int TIMEOUT {get; set;}
        public int SEND_EOI {get; set;}
        public int EOS_MODE {get; set;}
        public DateTime? ADDDATE {get; set;}
        public DateTime? MODDATE {get; set;}
    }
}