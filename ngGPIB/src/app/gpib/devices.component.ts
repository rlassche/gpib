import { Component, OnInit, Input } from '@angular/core';
import { taFieldsForm, typeaheadKeys } from '../common'
import { Observable, Observer } from 'rxjs';
import sampleData from '../../assets/config.hp-probook.json';

@Component({
  selector: 'app-devices',
  templateUrl: './devices.component.html',
  styleUrls: ['./devices.component.scss']
})
export class DevicesComponent implements OnInit {
  @Input('mode') mode: string = 'search';

  // The raw values in the input fields
  public taFieldsFormData: taFieldsForm = new taFieldsForm('');

  // This is filled whenver a typeahead suggested is SELECTED!
  private taKeysDict = new Map<string, typeaheadKeys>();
  public taFieldsTAError = new Map<string, boolean>();
  public xx:string;


  constructor() { }

  ngOnInit() {
    this.taFieldsFormData.gpib_device = 'xx'
    console.log( sampleData)
  }


// **********************************************************************************************
// TYPEAHEAD OBSERVABLE: getgpib_device$
// **********************************************************************************************
getgpib_device$: Observable<any[]> = Observable.create((observer: Observer<any[]>) => {
  // New search is required, so erase the key value for artist
  this.taKeysDict.delete('title')
  console.log('getgpib_device$: mode=', this.mode)

  //console.log("Calling service: getTitle:" + this.taFieldsFormData + ", taKeysDict: ", this.taKeysDict)
  //this.music_collection.getTitle(this.taFieldsFormData, this.taKeysDict).subscribe

  /*
  this.gpib_service.getgpib_device(this.taFieldsFormData, this.taKeysDict, this.mode).subscribe(
    (val: any) => {
      console.log('getTitle$: val: ', val.DATA);
      if (val.STATUS == "OK") {
        // ***************************************************************
        // SEND THE RECEIVED DATA TO THE SUBSCRIBERS,
        // So, to the typeahead form
        // ***************************************************************
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
  */
})
taIsLoading(x) {
  console.log( 'taIsLoading: ', x )
}

  /*
    * Check in the model value EQUALS the selectedOption:
    *  true  => Add inputLiteral class
    *  false => Add inputNew class
   */
  inputClass(ref) {
    console.log("inputClass: ", ref.name, ref.value)
    return {
      inputLiteral: this.taKeysDict.get(ref.name) !== undefined &&
        this.taFieldsFormData[ref.name] == this.taKeysDict.get(ref.name).typeaheadValue,
      inputNew: this.taFieldsFormData[ref.name] != '' && this.taFieldsTAError.get(ref.name),
      inputOptions: (this.taFieldsFormData[ref.name] != '' &&
        !this.taFieldsTAError.get(ref.name)),
    }
  }

}
