
using System;

namespace dnPrologix.server.Models {
    public partial class GpibDevice
    {
        internal AppDb _Db { get; set; }

        public GpibDevice() {}
        //public GpibDevice( AppDb db ) {
        //    _Db = db ;
        //}

        public string DEVICE_ID {get; set;}
        public string CONNECTION_TYPE {get; set;}
        public string DESCRIPTION {get; set;}
        public int MINOR {get; set;}
        public int PAD {get; set;}
        public int SAD {get; set;}
        public int TIMEOUT {get; set;}
        public int SEND_EOI {get; set;}
        public int EOS_MODE {get; set;}
        public DateTime? ADDDATE {get; set;}
        public DateTime? MODDATE {get; set;}
    }
}