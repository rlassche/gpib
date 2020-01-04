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
    console.log("ngOnInit")
    this.taFieldsFormData.DEVICE_ID = ''
    //console.log( sampleData)
  }

  //checkboxSel:boolean[] = new Array(100);
  checkboxSel: boolean[] = new Array();
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
          let i = 0;
          console.log(val)
          /*
          val.DATA.array.forEach(element => {
            console.log("set to true") ;
            this.checkboxSel[i++] = true;
          });
          */
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
  public data_to_send: string = '';

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
          let i = 0;
          console.log('onSelect: gpib_device ', this.gpib_device);
          console.log('onSelect: gpib_device.DEVICE_ID ', this.gpib_device.DEVICE_ID);
          this.gpib_device_functions = val.DEVICE_FUNCTION
          this.gpib_device_functions.forEach(element => {
            console.log("set to false");
            //this.checkboxSel[i++] = false;
            this.checkboxSel.push(false);
          });
          console.log('onSelect: gpib_device.DEVICE_FUNCTION ', this.gpib_device_functions);
        })
    }

  }
  checkboxSelect(item, i) {
    console.log('checkboxSelect: ' + i + ', code=' + this.gpib_device_functions[i].DEVICE_CODE, item)
  }
  checkboxChange(e, i) {
    console.log('checkboxChange', e, i)
    if (e.target.checked) {
      this.data_to_send += this.gpib_device_functions[i].DEVICE_CODE;
      console.log("YES, CHECKED, code ==", this.gpib_device_functions[i].DEVICE_CODE, this.data_to_send)
    } else {
      console.log("NO, NOT CHECKED")

    }
  }

  isInitialised: boolean = false;
  initDevice() {
    console.log("Initialse device: ", this.taKeysDict.get('DEVICE_ID').keyValue)
    this.rest.initDevice(this.taKeysDict.get('DEVICE_ID').keyValue).subscribe(
      (val) => {
        console.log(val)
        if (val.STATUS == "OK") {
          this.isInitialised = true;
        }
      });
  }
  //received: string = '**'
  sendToDevice(e) {
    //this.received = ''
    this.receivedData=''
    let obj = {
      DEVICE_ID: this.taKeysDict.get('DEVICE_ID').keyValue,
      DEVICE_COMMAND: this.data_to_send
    }
    console.log("sending to device: " , obj );

    this.rest.sendToDevice(obj).subscribe(
      (val) => {
        console.log(val)
        if (val.STATUS == "OK") {
          console.log("SEND OK: ", val)
        } else {
          //this.received = val.DEBUG;
        }
      });
  }
  receivedData
  readFromDevice(e) {
    let obj = {
      DEVICE_ID: this.taKeysDict.get('DEVICE_ID').keyValue
    }
    console.log( 'readFromDevice:', obj)
    this.rest.readFromDevice(obj).subscribe(
      (val) => {
        console.log(val)
        if (val.STATUS == "OK") {
          console.log("READ OK: ", val)
          this.receivedData = val.DATA;
        } else {
          console.log( "READ FAILED")
          //`this.received = val.DEBUG;
          this.receivedData = val.DEBUG;
        }
      });
  }

}
