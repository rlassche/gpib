import { Injectable } from '@angular/core';
import { Observable, of, forkJoin, throwError } from 'rxjs';
import { HttpClient, HttpErrorResponse, HttpParams, HttpHeaders } from '@angular/common/http';
import { taFieldsForm, typeaheadKeys} from './common'
//import sampleData from '../assets/config/hp-probook.json';

// Required needs this!
declare var require: any;

@Injectable({
  providedIn: 'root'
})
export class GpibrestService {
  private headers:HttpHeaders ;
  private RESTRoot: string
  private config;
  constructor(private http: HttpClient) { 
    this.config = require('../assets/config.' + location.hostname + '.json');
    console.log('Require: ../assets/config.' + location.hostname + '.json');

    this.headers = new HttpHeaders({
      "Content-Type": "multipart/form-data"
    });
    this.RESTRoot = this.config.RestServer;
    console.log( "RESTRoot="+this.RESTRoot)
  }

  taGetDevice(formFields:taFieldsForm , keys:Map<string,typeaheadKeys>, mode:string):Observable<any>  {
    //console.log( taFieldsForm)
    console.log( "taGetDevice: RestServer="+this.config.RestServer + '/taGetDevice')
    return this.http.post<any>(this.RESTRoot + '/taGetDevice',
            { MODE: mode, CURRENT_FIELD: 'DEVICE_ID', FORM_FIELDS: formFields, KEYS: Array.from(keys.entries())},
            { headers: this.headers});

  }


  documentation( device_id:string):Observable<any>  {
    console.log( "documentation: RestServer="+this.config.RestServer + '/documentation, device_id=' + device_id)
    return this.http.post<any>(this.RESTRoot + '/documentation',
            { DEVICE_ID: device_id },
            { headers: this.headers});

  }

  getDeviceInfo(formFields:taFieldsForm , keys:Map<string,typeaheadKeys>, mode:string):Observable<any>  {
    //console.log( taFieldsForm)
    console.log( typeaheadKeys)
    console.log( "getDeviceInfo: RestServer="+this.config.RestServer + '/getDeviceInfo')
    return this.http.post<any>(this.RESTRoot + '/getDeviceInfo',
            { MODE: mode, FORM_FIELDS: formFields, KEYS: Array.from(keys.entries())},
            { headers: this.headers});

  }

  initDevice( device_id:string ) {
    //console.log( taFieldsForm)
    console.log( "initDevice: RestServer="+this.config.RestServer + '/initDevice')
    return this.http.post<any>(this.RESTRoot + '/initDevice',
            { DEVICE_ID: device_id },
            { headers: this.headers});

  }
  
  sendToDevice( obj:any ) {
    //console.log( taFieldsForm)
    console.log( "sendToDevice: RestServer="+this.config.RestServer + '/sendToDevice', obj)
    return this.http.post<any>(this.RESTRoot + '/sendToDevice',
            obj,
            { headers: this.headers});

  }

  readFromDevice( obj:any) {
    console.log( "readFromDevice: RestServer="+this.config.RestServer + '/readFromDevice', obj)
    return this.http.post<any>(this.RESTRoot + '/readFromDevice',
            obj,
            { headers: this.headers});

  }
}
