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
    //console.log( sampleData)

    this.headers = new HttpHeaders({
      "Content-Type": "multipart/form-data"
    });
    this.RESTRoot = this.config.RestServer;

  }

  ta_GPIB_Device(formFields:taFieldsForm , keys:Map<string,typeaheadKeys>, mode:string):Observable<any>  {
    console.log( "ta_GPIB_Device: RestServer="+this.config.RestServer)
    return this.http.post<any>(this.RESTRoot + '/ta_GPIB_Device',
            { MODE: mode, CURRENT_FIELD: 'artist', FORM_FIELDS: formFields, KEYS: Array.from(keys.entries())},
            { headers: this.headers});

  }
}
