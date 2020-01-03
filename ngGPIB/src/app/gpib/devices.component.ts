import { Component, OnInit, Input } from '@angular/core';
import { taFieldsForm, typeaheadKeys, GPIB_DEVICE, DEVICE_FUNCTION } from '../common'
import { Observable, Observer, throwError } from 'rxjs';
import { GpibrestService } from '../gpibrest.service'
import { HttpErrorResponse } from '@angular/common/http';
import { TypeaheadMatch } from 'ngx-bootstrap';
//import sampleData from '../../assets/config.hp-probook.json';

@Component({
  selector: 'app-devices',
  templateUrl: './devices.component.html',
  styleUrls: ['./devices.component.scss']
})
export class DevicesComponent implements OnInit {
  @Input('mode') mode: string = 'search';

  errorMessage: string
  // The raw values in the input fields
  public taFieldsFormData: taFieldsForm = new taFieldsForm('');

  // This is filled whenver a typeahead suggested is SELECTED!
  private taKeysDict = new Map<string, typeaheadKeys>();
  public taFieldsTAError = new Map<string, boolean>();
  //public xx:string;

  constructor(private rest: GpibrestService) {
    console.log("devices.component: constructor")
  }

  ngOnInit() {
    console.log( "ngOnInit")
    this.taFieldsFormData.DEVICE_ID = ''
    //console.log( sampleData)
  }


  // **********************************************************************************************
  // TYPEAHEAD OBSERVABLE: taGetDevices$
  // **********************************************************************************************
  public taGetDevice$: Observable<any[]> = Observable.create((observer: Observer<any[]>) => {
    // New search is required, so erase the key value for artist
    this.taKeysDict.delete('DEVICE_ID')
    console.log('taGetDevice$: mode=', this.mode)

    //console.log("Calling service: getTitle:" + this.taFieldsFormData + ", taKeysDict: ", this.taKeysDict)
    //this.music_collection.getTitle(this.taFieldsFormData, this.taKeysDict).subscribe

    this.rest.taGetDevice(this.taFieldsFormData, this.taKeysDict, this.mode).subscribe(
      (val: any) => {
        console.log('taGetDevice$: val: ', val.DATA);
        if (val.STATUS == "OK") {
          // ***************************************************************
          // SEND THE RECEIVED DATA TO THE SUBSCRIBERS,
          // So, to the typeahead form
          // ***************************************************************
          console.log('Received from REST server: ', val)
          observer.next(val.DATA);
        } else {
          observer.error('error in  IS WRONG!')
        }
      },
      (error: HttpErrorResponse) => {
        this.errorMessage = "getgpib_device$:ERROR:Probleem met de Hypnotoad server!";
        throwError('Apache web server is down!');
      }
    );
  })


  taIsLoading(x) {
    console.log('taIsLoading: ', x)
  }

  /*
    * Check in the model value EQUALS the selectedOption:
    *  true  => Add inputLiteral class
    *  false => Add inputNew class
   */
  inputClass(ref) {
    //console.log("inputClass: ", ref.name, ref.value)
    return {
      inputLiteral: this.taKeysDict.get(ref.name) !== undefined &&
        this.taFieldsFormData[ref.name] == this.taKeysDict.get(ref.name).typeaheadValue,
      inputNew: this.taFieldsFormData[ref.name] != '' && this.taFieldsTAError.get(ref.name),
      inputOptions: (this.taFieldsFormData[ref.name] != '' &&
        !this.taFieldsTAError.get(ref.name)),
    }
  }
  typeaheadNoResults(f, e) {
    console.log("typeaheadNoResults")
  }

  public gpib_device: GPIB_DEVICE
  public gpib_device_functions: DEVICE_FUNCTION[]

  onSelect(e: TypeaheadMatch, h: HTMLInputElement) {
    console.log("onSelect: item.ID=***" + e.item.ID + '****', h.name)
    console.log(h)
    this.taKeysDict.set(h.name,
      {
        keyColumnName: h.name,
        keyValue: e.item.ID,
        typeaheadColumnName: h.getAttribute('typeaheadoptionfield'),
        typeaheadValue: h.value
      });
    console.log("taKeysDict: ", this.taKeysDict)
    if (h.name == "DEVICE_ID") {
      this.rest.getDeviceInfo(this.taFieldsFormData, this.taKeysDict, 'search').subscribe(
        (val) => {
          this.gpib_device = val.GPIB_DEVICE[0];
          console.log('onSelect: gpib_device ', this.gpib_device);
          console.log('onSelect: gpib_device.DEVICE_ID ', this.gpib_device.DEVICE_ID);
          this.gpib_device_functions = val.DEVICE_FUNCTION
          console.log('onSelect: gpib_device.DEVICE_FUNCTION ', this.gpib_device_functions);
        })
    }

  }
  checkboxSelect( item, i ) {
    console.log( 'checkboxSelect: '+i+', code='+this.gpib_device_functions[i].DEVICE_CODE, item)
  }
  checkboxChange( e, i) {
    console.log( 'checkboxChange', e, i )
    if( e.target.checked ) {
      console.log( "YES, CHECKED, code ==", this.gpib_device_functions[i].DEVICE_CODE)
    } else {
      console.log( "NO, NOT CHECKED")

    }
  }

}
